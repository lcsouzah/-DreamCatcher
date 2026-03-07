package com.dreamcatcher.dreamcatcher.health

import android.app.Activity
import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.Duration
import java.time.Instant

class HealthConnectBridge(
    private val activity: Activity,
    private val context: Context
) : MethodChannel.MethodCallHandler {

    private val client by lazy { HealthConnectClient.getOrCreate(context) }

    private val sleepPermissions = setOf(
        HealthPermission.getReadPermission(SleepSessionRecord::class)
    )

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "isAvailable" -> {
                val status = HealthConnectClient.getSdkStatus(context)
                result.success(status == HealthConnectClient.SDK_AVAILABLE)
            }

            "hasSleepPermission" -> {
                CoroutineScope(Dispatchers.Main).launch {
                    val granted = client.permissionController.getGrantedPermissions()
                    result.success(granted.containsAll(sleepPermissions))
                }
            }

            "readLastSleepSession" -> {
                CoroutineScope(Dispatchers.Main).launch {
                    try {
                        val session = readLastSleep()
                        result.success(session)
                    } catch (e: Exception) {
                        result.error("READ_FAILED", e.message, null)
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    private suspend fun readLastSleep(): Map<String, Any?>? = withContext(Dispatchers.IO) {
        val now = Instant.now()
        val from = now.minusSeconds(60L * 60L * 36L) // last 36 hours

        val response = client.readRecords(
            ReadRecordsRequest(
                recordType = SleepSessionRecord::class,
                timeRangeFilter = TimeRangeFilter.between(from, now)
            )
        )

        val last = response.records.maxByOrNull { it.endTime } ?: return@withContext null
        val minutes = Duration.between(last.startTime, last.endTime).toMinutes()

        mapOf(
            "startTime" to last.startTime.toString(),
            "endTime" to last.endTime.toString(),
            "durationMinutes" to minutes,
            "title" to last.title,
            "notes" to last.notes
        )
    }
}
