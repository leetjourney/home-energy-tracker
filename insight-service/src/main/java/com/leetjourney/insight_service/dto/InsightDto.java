package com.leetjourney.insight_service.dto;

import lombok.Builder;

@Builder
public record InsightDto(
    Long userId,
    String tips,
    double energyUsage
) {
}
