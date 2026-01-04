package com.leetjourney.insight_service.dto;

import lombok.Builder;

@Builder
public record DeviceDto(
        Long id,
        String name,
        String type,
        String location,
        double energyConsumed
) {
}
