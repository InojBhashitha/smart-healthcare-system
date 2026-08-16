package com.smarthealthcare.web;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class WebBackendApplicationTests {

	@Autowired
	private MockMvc mockMvc;

	@Test
	void testProfileWithPharmacy() throws Exception {
		// 1. Login with a user who HAS a pharmacy (e.g. pharmacy1@example.com)
		String loginPayload = "{\"email\":\"pharmacy1@example.com\",\"password\":\"pharmacy123\"}";
		
		String response = mockMvc.perform(post("/api/web/auth/login")
				.contentType(MediaType.APPLICATION_JSON)
				.content(loginPayload))
				.andExpect(status().isOk())
				.andReturn()
				.getResponse()
				.getContentAsString();
		
		String token = response.split("\"token\":\"")[1].split("\"")[0];
		
		// 2. Perform GET /api/web/profile with Bearer token
		mockMvc.perform(get("/api/web/profile")
				.header("Authorization", "Bearer " + token))
				.andDo(print());
	}

	@Test
	void testStockEndpoint() throws Exception {
		// 1. Login
		String loginPayload = "{\"email\":\"pharmacy1@example.com\",\"password\":\"pharmacy123\"}";
		String response = mockMvc.perform(post("/api/web/auth/login")
				.contentType(MediaType.APPLICATION_JSON)
				.content(loginPayload))
				.andExpect(status().isOk())
				.andReturn()
				.getResponse()
				.getContentAsString();
		
		String token = response.split("\"token\":\"")[1].split("\"")[0];
		
		// 2. Access GET /api/web/stock
		mockMvc.perform(get("/api/web/stock")
				.header("Authorization", "Bearer " + token))
				.andDo(print())
				.andExpect(status().isOk());
	}
}
