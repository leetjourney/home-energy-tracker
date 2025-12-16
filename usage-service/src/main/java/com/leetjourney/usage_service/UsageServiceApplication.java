package com.leetjourney.usage_service;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class UsageServiceApplication {

	public static void main(String[] args) {
		SpringApplication.run(UsageServiceApplication.class, args);
	}

}
