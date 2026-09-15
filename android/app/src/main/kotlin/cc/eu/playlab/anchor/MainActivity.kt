package cc.eu.playlab.anchor

import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.ArrayDeque
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val allowedDocumentUris = mutableSetOf<String>()
    private var pendingDirectoryResult: MethodChannel.Result? = null
    private lateinit var projectDirectoryChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        projectDirectoryChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PROJECT_DIRECTORY_CHANNEL,
        )
        projectDirectoryChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDirectory" -> pickDirectory(result)
                "listDirectory" -> listDirectory(call, result)
                "readFile" -> readFile(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        if (pendingDirectoryResult != null) {
            result.error("picker_busy", "A directory picker is already open.", null)
            return
        }
        pendingDirectoryResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
            )
        }
        startActivityForResult(intent, DIRECTORY_REQUEST_CODE)
    }

    @Deprecated("Deprecated in Android, retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != DIRECTORY_REQUEST_CODE) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        val result = pendingDirectoryResult ?: return
        pendingDirectoryResult = null
        val treeUri = data?.data
        if (resultCode != RESULT_OK || treeUri == null) {
            result.success(null)
            return
        }

        try {
            contentResolver.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
            val root = DocumentFile.fromTreeUri(this, treeUri)
            result.success(
                mapOf(
                    "sourceUri" to treeUri.toString(),
                    "displayName" to (root?.name ?: "Android project"),
                ),
            )
        } catch (error: SecurityException) {
            result.error(
                "directory_permission_denied",
                "Could not persist read access to the selected directory.",
                error.message,
            )
        }
    }

    private fun listDirectory(call: MethodCall, result: MethodChannel.Result) {
        val treeUriValue = call.argument<String>("treeUri")
        if (treeUriValue.isNullOrBlank()) {
            result.error("invalid_arguments", "treeUri is required.", null)
            return
        }
        val maxEntries = (call.argument<Number>("maxEntries")?.toInt() ?: 2000)
            .coerceIn(1, MAX_DIRECTORY_ENTRIES)

        ioExecutor.execute {
            try {
                val treeUri = Uri.parse(treeUriValue)
                requirePersistedReadPermission(treeUri)
                val root = DocumentFile.fromTreeUri(this, treeUri)
                    ?: throw IllegalArgumentException("Invalid directory URI.")
                if (!root.exists() || !root.isDirectory) {
                    throw IllegalArgumentException("Selected document is not a directory.")
                }

                val entries = mutableListOf<Map<String, Any>>()
                val directories = ArrayDeque<Pair<DocumentFile, String>>()
                directories.add(root to "")
                var visitedEntries = 0

                while (directories.isNotEmpty()) {
                    val (directory, prefix) = directories.removeFirst()
                    for (child in directory.listFiles()) {
                        visitedEntries += 1
                        if (visitedEntries > maxEntries) {
                            throw DirectoryTooLargeException(maxEntries)
                        }
                        val name = child.name ?: continue
                        val relativePath = if (prefix.isEmpty()) name else "$prefix/$name"
                        when {
                            child.isDirectory -> directories.add(child to relativePath)
                            child.isFile -> entries.add(
                                mapOf(
                                    "relativePath" to relativePath,
                                    "byteLength" to child.length(),
                                    "documentUri" to child.uri.toString(),
                                ),
                            )
                        }
                    }
                }

                allowedDocumentUris.clear()
                allowedDocumentUris.addAll(
                    entries.map { it.getValue("documentUri") as String },
                )
                postSuccess(result, entries)
            } catch (error: DirectoryTooLargeException) {
                postError(
                    result,
                    "directory_too_large",
                    "Directory exceeds the ${error.maxEntries}-entry safety limit.",
                )
            } catch (error: SecurityException) {
                postError(result, "directory_permission_denied", error.message)
            } catch (error: Exception) {
                postError(result, "directory_read_failed", error.message)
            }
        }
    }

    private fun readFile(call: MethodCall, result: MethodChannel.Result) {
        val documentUriValue = call.argument<String>("documentUri")
        if (documentUriValue.isNullOrBlank()) {
            result.error("invalid_arguments", "documentUri is required.", null)
            return
        }
        val maxBytes = (call.argument<Number>("maxBytes")?.toInt() ?: DEFAULT_MAX_FILE_BYTES)
            .coerceIn(1, MAX_FILE_READ_BYTES)

        ioExecutor.execute {
            try {
                if (!allowedDocumentUris.contains(documentUriValue)) {
                    throw SecurityException("Document URI is outside the active directory listing.")
                }
                val stream = contentResolver.openInputStream(Uri.parse(documentUriValue))
                    ?: throw IllegalStateException("Could not open the selected document.")
                val output = ByteArrayOutputStream(minOf(maxBytes, 64 * 1024))
                stream.use { input ->
                    val buffer = ByteArray(32 * 1024)
                    var total = 0
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        total += count
                        if (total > maxBytes) throw FileTooLargeException(maxBytes)
                        output.write(buffer, 0, count)
                    }
                }
                postSuccess(result, output.toByteArray())
            } catch (error: FileTooLargeException) {
                postError(
                    result,
                    "file_too_large",
                    "File exceeds the ${error.maxBytes}-byte safety limit.",
                )
            } catch (error: SecurityException) {
                postError(result, "directory_permission_denied", error.message)
            } catch (error: Exception) {
                postError(result, "file_read_failed", error.message)
            }
        }
    }

    private fun requirePersistedReadPermission(treeUri: Uri) {
        val hasPermission = contentResolver.persistedUriPermissions.any {
            it.uri == treeUri && it.isReadPermission
        }
        if (!hasPermission) {
            throw SecurityException("Read access to the selected directory is no longer available.")
        }
    }

    private fun postSuccess(result: MethodChannel.Result, value: Any?) {
        runOnUiThread { result.success(value) }
    }

    private fun postError(result: MethodChannel.Result, code: String, message: String?) {
        runOnUiThread { result.error(code, message ?: code, null) }
    }

    override fun onDestroy() {
        if (::projectDirectoryChannel.isInitialized) {
            projectDirectoryChannel.setMethodCallHandler(null)
        }
        pendingDirectoryResult?.error(
            "activity_destroyed",
            "Directory picker closed because the activity was destroyed.",
            null,
        )
        pendingDirectoryResult = null
        ioExecutor.shutdownNow()
        super.onDestroy()
    }

    private class DirectoryTooLargeException(val maxEntries: Int) : Exception()
    private class FileTooLargeException(val maxBytes: Int) : Exception()

    companion object {
        private const val PROJECT_DIRECTORY_CHANNEL =
            "cc.eu.playlab.anchor/project_directory"
        private const val DIRECTORY_REQUEST_CODE = 7401
        private const val MAX_DIRECTORY_ENTRIES = 10_000
        private const val DEFAULT_MAX_FILE_BYTES = 512 * 1024
        private const val MAX_FILE_READ_BYTES = 16 * 1024 * 1024
    }
}
