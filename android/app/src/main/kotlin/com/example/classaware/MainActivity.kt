package com.example.classaware

import android.content.ComponentName
import android.content.Context
import android.content.Intent
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
                else -> {
                    result.notImplemented()
                }
            }
        }
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
                            // 获取应用图标的Base64编码
                            val iconBase64 = getAppIconBase64(componentName)
                            
                            appList.add(mapOf(
                                "name" to appName,
                                "packageName" to packageName,
                                "icon" to iconBase64
                            ))
                        } catch (e: Exception) {
                            // 跳过无法获取信息的应用
                        }
                    }
                }
            } catch (e: Exception) {
                // 跳过无法访问的用户配置文件
            }
        }
        
        return appList.sortedBy { it["name"] }
    }
    
    /**
     * 获取应用图标的Base64编码
     */
    private fun getAppIconBase64(componentName: ComponentName): String {
        return try {
            val packageManager = packageManager
            val drawable = packageManager.getActivityIcon(componentName)
            val bitmap = drawableToBitmap(drawable)
            val outputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
        } catch (e: Exception) {
            "" // 返回空字符串表示无图标
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
