package com.example.classaware

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.nfc.NfcAdapter
import android.content.pm.LauncherApps
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.UserHandle
import android.os.UserManager
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import im.nfc.flutter_nfc_kit.FlutterNfcKitPlugin

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.classaware/launcher"
    private lateinit var appFilter: AppFilter

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 初始化AppFilter
        appFilter = AppFilter(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLaunchableApps" -> {
                    try {
                        val launchableApps = getLaunchableAppsWithLauncherService()
                        result.success(launchableApps)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get launchable apps", e.message)
                    }
                }
                "getAppIcon" -> {
                    try {
                        val packageName = call.argument<String>("packageName")
                        if (packageName.isNullOrEmpty()) {
                            result.error("ERROR", "Missing packageName", null)
                        } else {
                            Thread {
                                try {
                                    val bytes = getApplicationIconBytes(packageName)
                                    runOnUiThread { result.success(bytes) }
                                } catch (e: Exception) {
                                    runOnUiThread { result.error("ERROR", "Failed to get app icon", e.message) }
                                }
                            }.start()
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get app icon", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(this)
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            this, 0, Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_MUTABLE
        )
        adapter?.enableForegroundDispatch(this, pendingIntent, null, null)
    }

    override fun onPause() {
        super.onPause()
        val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(this)
        adapter?.disableForegroundDispatch(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val tag: android.nfc.Tag? = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
        tag?.apply(FlutterNfcKitPlugin::handleTag)
    }
    
    // 使用LauncherApps服务获取应用 - 参考Lawnchair实现
    private fun getLaunchableAppsWithLauncherService(): List<Map<String, String>> {
        val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps
        val userManager = getSystemService(Context.USER_SERVICE) as UserManager
        val appList = mutableListOf<Map<String, String>>()
        val addedPackages = mutableSetOf<String>()
        
        // 获取所有用户配置文件
        val userProfiles = userManager.userProfiles
        
        for (userHandle in userProfiles) {
            try {
                // 使用LauncherApps获取该用户的所有可启动应用
                val activities = launcherApps.getActivityList(null, userHandle)
                
                for (activityInfo in activities) {
                    val componentName = activityInfo.componentName
                    val packageName = componentName.packageName
                    
                    // 使用AppFilter进行过滤
                    if (appFilter.shouldShowApp(componentName) && !addedPackages.contains(packageName)) {
                        addedPackages.add(packageName)
                        
                        try {
                            val appName = activityInfo.label.toString()
                            appList.add(mapOf(
                                "name" to appName,
                                "packageName" to packageName
                            ))
                        } catch (_: Exception) {}
                    }
                }
            } catch (e: Exception) {
                // 跳过无法访问的用户配置文件
            }
        }
        
        return appList.sortedBy { it["name"] }
    }
    
    private fun getApplicationIconBytes(packageName: String): ByteArray? {
        return try {
            val pm = packageManager
            val drawable = pm.getApplicationIcon(packageName)
            val src = drawableToBitmap(drawable)
            val density = resources.displayMetrics.density
            val sizePx = (48 * density).toInt().coerceAtLeast(32)
            val bmp = if (src.width != sizePx || src.height != sizePx) {
                Bitmap.createScaledBitmap(src, sizePx, sizePx, true)
            } else src
            val outputStream = ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.PNG, 80, outputStream)
            outputStream.toByteArray()
        } catch (_: Exception) {
            null
        }
    }
    
    /**
     * 将Drawable转换为Bitmap
     */
    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            return drawable.bitmap
        }
        
        val bitmap = Bitmap.createBitmap(
            drawable.intrinsicWidth.coerceAtLeast(1),
            drawable.intrinsicHeight.coerceAtLeast(1),
            Bitmap.Config.ARGB_8888
        )
        
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        
        return bitmap
    }
}
