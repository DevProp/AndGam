package com.mathquest.plugin;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.os.VibratorManager;
import android.util.Log;
import android.widget.Toast;
import org.godotengine.godot.Godot;
import org.godotengine.godot.GodotPlugin;
import org.json.JSONObject;

/**
 * MathQuestPlugin - Native Android Plugin for Godot 4.x
 * 
 * Provides native Android functionality including:
 * - Haptic feedback with various patterns
 * - Performance monitoring (CPU, memory, FPS)
 * - Play Games Services integration hooks
 * - System dialogs and native UI
 * - Device information access
 * 
 * Usage in Godot:
 *   var plugin = Engine.get_singleton("MathQuestPlugin")
 *   plugin.triggerHapticLight()
 */
public class MathQuestPlugin extends GodotPlugin {
    
    private static final String TAG = "MathQuestPlugin";
    private static final String PLUGIN_NAME = "MathQuestPlugin";
    
    // Haptic pattern durations (milliseconds)
    private static final int HAPTIC_LIGHT_DURATION = 50;
    private static final int HAPTIC_MEDIUM_DURATION = 100;
    private static final int HAPTIC_HEAVY_DURATION = 200;
    private static final long[] HAPTIC_SUCCESS_PATTERN = {0, 50, 50, 50, 100};
    private static final long[] HAPTIC_ERROR_PATTERN = {0, 100, 50, 100};
    
    private final Activity activity;
    private final Context context;
    private Vibrator vibrator;
    
    /**
     * Constructor - Called by Godot engine when plugin is loaded
     */
    public MathQuestPlugin(Godot godot) {
        super(godot);
        this.activity = godot.getActivity();
        this.context = activity.getApplicationContext();
        initializeVibrator();
        Log.i(TAG, "Plugin initialized");
    }
    
    /**
     * Returns the plugin name as registered in Godot
     */
    @Override
    public String getPluginName() {
        return PLUGIN_NAME;
    }
    
    /**
     * Initialize Vibrator service
     */
    private void initializeVibrator() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            VibratorManager vibratorManager = (VibratorManager) context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE);
            vibrator = vibratorManager.getDefaultVibrator();
        } else {
            vibrator = (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
        }
    }
    
    // ============================================================================
    // HAPTIC FEEDBACK METHODS
    // ============================================================================
    
    /**
     * Trigger light haptic feedback (short vibration)
     */
    public void triggerHapticLight() {
        triggerHapticVibration(HAPTIC_LIGHT_DURATION);
    }
    
    /**
     * Trigger medium haptic feedback
     */
    public void triggerHapticMedium() {
        triggerHapticVibration(HAPTIC_MEDIUM_DURATION);
    }
    
    /**
     * Trigger heavy haptic feedback (long vibration)
     */
    public void triggerHapticHeavy() {
        triggerHapticVibration(HAPTIC_HEAVY_DURATION);
    }
    
    /**
     * Trigger success pattern haptic feedback
     */
    public void triggerHapticSuccess() {
        triggerHapticPattern(HAPTIC_SUCCESS_PATTERN);
    }
    
    /**
     * Trigger error pattern haptic feedback
     */
    public void triggerHapticError() {
        triggerHapticPattern(HAPTIC_ERROR_PATTERN);
    }
    
    /**
     * Trigger vibration for specified duration
     * @param durationMs Duration in milliseconds
     */
    public void triggerHapticVibration(int durationMs) {
        if (vibrator != null && vibrator.hasVibrator()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE));
            } else {
                vibrator.vibrate(durationMs);
            }
        }
    }
    
    /**
     * Trigger custom haptic pattern
     * @param pattern Array of durations [off, on, off, on, ...] in milliseconds
     */
    public void triggerHapticPattern(long[] pattern) {
        if (vibrator != null && vibrator.hasVibrator()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, VibrationEffect.DEFAULT_AMPLITUDE));
            } else {
                vibrator.vibrate(pattern, -1);
            }
        }
    }
    
    // ============================================================================
    // SYSTEM DIALOGS & NATIVE UI
    // ============================================================================
    
    /**
     * Show Android Toast message
     * @param message Message to display
     */
    public void showToast(final String message) {
        if (activity != null) {
            activity.runOnUiThread(() -> {
                Toast.makeText(context, message, Toast.LENGTH_SHORT).show();
            });
        }
    }
    
    /**
     * Show rate app dialog (placeholder - implement with Play Store intent)
     */
    public void showRateAppDialog() {
        // TODO: Implement Play Store rating dialog
        Log.i(TAG, "Rate app dialog requested");
    }
    
    /**
     * Share content to social media
     * @param title Share title
     * @param text Share text
     * @param url Optional URL to share
     */
    public void shareToSocialMedia(String title, String text, String url) {
        // TODO: Implement Android share intent
        Log.i(TAG, "Share requested: " + title);
    }
    
    // ============================================================================
    // DEVICE INFORMATION
    // ============================================================================
    
    /**
     * Get device information as JSON string
     * @return JSON string with device info
     */
    public String getDeviceInfo() {
        JSONObject deviceInfo = new JSONObject();
        try {
            deviceInfo.put("manufacturer", Build.MANUFACTURER);
            deviceInfo.put("model", Build.MODEL);
            deviceInfo.put("android_version", Build.VERSION.RELEASE);
            deviceInfo.put("sdk_level", Build.VERSION.SDK_INT);
            deviceInfo.put("memory_class_mb", getMemoryClassMb());
        } catch (Exception e) {
            Log.e(TAG, "Error getting device info", e);
        }
        return deviceInfo.toString();
    }
    
    /**
     * Get battery level percentage
     * @return Battery level 0-100, or -1 if unavailable
     */
    public int getBatteryLevel() {
        // TODO: Implement battery level detection
        return -1;
    }
    
    /**
     * Check if device is charging
     * @return true if charging, false otherwise
     */
    public boolean isCharging() {
        // TODO: Implement charging status detection
        return false;
    }
    
    /**
     * Get network type (WiFi, Cellular, etc.)
     * @return Network type string
     */
    public String getNetworkType() {
        // TODO: Implement network type detection
        return "unknown";
    }
    
    /**
     * Get device memory class in MB
     */
    private int getMemoryClassMb() {
        return (int) (Runtime.getRuntime().maxMemory() / (1024 * 1024));
    }
    
    // ============================================================================
    // PERFORMANCE MONITORING (Placeholder methods)
    // ============================================================================
    
    /**
     * Start performance monitoring
     */
    public void startPerformanceMonitoring() {
        Log.i(TAG, "Performance monitoring started");
        // TODO: Implement periodic performance data collection
    }
    
    /**
     * Stop performance monitoring
     */
    public void stopPerformanceMonitoring() {
        Log.i(TAG, "Performance monitoring stopped");
    }
    
    /**
     * Request current performance data
     * @return JSON string with CPU, memory, FPS data
     */
    public String requestPerformanceData() {
        JSONObject perfData = new JSONObject();
        try {
            Runtime runtime = Runtime.getRuntime();
            long usedMemory = runtime.totalMemory() - runtime.freeMemory();
            perfData.put("memoryMB", usedMemory / (1024 * 1024));
            perfData.put("cpuUsage", 0.0);  // Requires native implementation
            perfData.put("fps", 60.0);      // Should query from Godot
        } catch (Exception e) {
            Log.e(TAG, "Error getting performance data", e);
        }
        return perfData.toString();
    }
    
    // ============================================================================
    // PLAY GAMES SERVICES (Placeholder methods)
    // ============================================================================
    
    /**
     * Sign in to Google Play Games
     */
    public void signInToPlayGames() {
        Log.i(TAG, "Play Games sign-in requested");
        // TODO: Implement Play Games Services sign-in
    }
    
    /**
     * Sign out from Google Play Games
     */
    public void signOutFromPlayGames() {
        Log.i(TAG, "Play Games sign-out requested");
    }
    
    /**
     * Check if connected to Play Games
     * @return true if connected
     */
    public boolean isPlayGamesConnected() {
        return false;
    }
    
    /**
     * Submit score to leaderboard
     * @param leaderboardId Leaderboard ID
     * @param score Score value
     */
    public void submitScore(String leaderboardId, int score) {
        Log.i(TAG, "Submit score: " + leaderboardId + " = " + score);
    }
    
    /**
     * Unlock achievement
     * @param achievementId Achievement ID
     */
    public void unlockAchievement(String achievementId) {
        Log.i(TAG, "Unlock achievement: " + achievementId);
    }
    
    /**
     * Show leaderboard UI
     * @param leaderboardId Leaderboard ID to show
     */
    public void showLeaderboard(String leaderboardId) {
        Log.i(TAG, "Show leaderboard: " + leaderboardId);
    }
    
    /**
     * Show achievements UI
     */
    public void showAchievements() {
        Log.i(TAG, "Show achievements requested");
    }
    
    // ============================================================================
    // ANALYTICS (Placeholder methods)
    // ============================================================================
    
    /**
     * Log analytics event
     * @param eventName Event name
     * @param parameters Event parameters as JSON string
     */
    public void logAnalyticsEvent(String eventName, String parameters) {
        Log.i(TAG, "Analytics event: " + eventName + " params: " + parameters);
    }
    
    /**
     * Log screen view
     * @param screenName Screen name
     */
    public void logScreenView(String screenName) {
        Log.i(TAG, "Screen view: " + screenName);
    }
    
    /**
     * Log error to Crashlytics/analytics
     * @param errorCode Error code
     * @param message Error message
     * @param stackTrace Stack trace
     */
    public void logError(String errorCode, String message, String stackTrace) {
        Log.e(TAG, "Error logged: " + errorCode + " - " + message);
    }
}
