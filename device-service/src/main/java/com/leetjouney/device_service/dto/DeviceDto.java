package com.leetjouney.device_service.dto;

import com.leetjouney.device_service.model.DeviceType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@NoArgsConstructor
@Builder
@Data
public class DeviceDto {
    private Long id;
    private String name;
    private DeviceType type;
    private String location;
    private Long userId;
}
