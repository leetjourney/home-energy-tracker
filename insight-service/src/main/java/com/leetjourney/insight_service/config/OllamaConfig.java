package com.leetjourney.insight_service.config;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OllamaConfig {
    @Bean
    ChatClient chatClient(ChatClient.Builder builder) {
        return builder
                .defaultSystem("You are an expert energy efficiency advisor. " +
                        "Provide concise and practical advice to users on how to reduce " +
                        "their energy consumption based on their usage patterns.")
                .build();
    }
}
