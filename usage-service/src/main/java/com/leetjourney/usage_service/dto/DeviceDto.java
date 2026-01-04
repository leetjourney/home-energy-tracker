package com.leetjourney.usage_service.dto;

import lombok.Builder;
import lombok.Setter;

@Builder
public record DeviceDto(Long id,
                        String name,
                        String type,
                        String location,
                        Long userId,
                        Double energyConsumed) {
}
