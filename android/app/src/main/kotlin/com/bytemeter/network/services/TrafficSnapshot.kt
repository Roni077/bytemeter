package com.bytemeter.network.services

data class TrafficSnapshot(
    val up: Long,
    val down: Long,
    val interfaces: Set<String>,
    val timestamp: Long = System.currentTimeMillis()
) {
    val total: Long get() = up + down

    operator fun minus(other: TrafficSnapshot): TrafficSnapshot {
        return if (interfaces != other.interfaces) {
            TrafficSnapshot(0L, 0L, interfaces, timestamp)
        } else {
            TrafficSnapshot(
                up = (up - other.up).coerceAtLeast(0L),
                down = (down - other.down).coerceAtLeast(0L),
                interfaces = interfaces,
                timestamp = timestamp
            )
        }
    }

    fun toMap(): Map<String, Any> {
        return mapOf(
            "upBytesPerSec" to up,
            "downBytesPerSec" to down,
            "totalBytesPerSec" to total,
            "interfaces" to interfaces.toList(),
            "timestamp" to timestamp
        )
    }
}
