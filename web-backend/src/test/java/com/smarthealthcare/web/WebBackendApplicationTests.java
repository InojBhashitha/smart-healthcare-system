package com.smarthealthcare.web;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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

	@Test
	void testProfileEditDetailsAndLocation() throws Exception {
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
		
		// 2. GET current profile to record initial details
		mockMvc.perform(get("/api/web/profile")
				.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk());

		// 3. PUT update details
		String updatePayload = "{"
				+ "\"pharmacyName\":\"MediCo Pharmacy Test\","
				+ "\"email\":\"pharmacy1@example.com\","
				+ "\"phone\":\"0771234567\","
				+ "\"address\":\"Boralesgamuwa West\""
				+ "}";
		
		mockMvc.perform(put("/api/web/profile")
				.header("Authorization", "Bearer " + token)
				.contentType(MediaType.APPLICATION_JSON)
				.content(updatePayload))
				.andExpect(status().isOk());
		
		// 4. GET profile again and verify updated values
		String getResponse = mockMvc.perform(get("/api/web/profile")
				.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk())
				.andReturn()
				.getResponse()
				.getContentAsString();
		
		org.junit.jupiter.api.Assertions.assertTrue(getResponse.contains("MediCo Pharmacy Test"));
		org.junit.jupiter.api.Assertions.assertTrue(getResponse.contains("0771234567"));
		org.junit.jupiter.api.Assertions.assertTrue(getResponse.contains("Boralesgamuwa West"));

		// 5. Revert details to original to keep database clean
		String revertPayload = "{"
				+ "\"pharmacyName\":\"MediCo Pharmacy\","
				+ "\"email\":\"pharmacy1@example.com\","
				+ "\"phone\":\"0114567890\","
				+ "\"address\":\"Boralesgamuwa\""
				+ "}";
		mockMvc.perform(put("/api/web/profile")
				.header("Authorization", "Bearer " + token)
				.contentType(MediaType.APPLICATION_JSON)
				.content(revertPayload))
				.andExpect(status().isOk());

		// 6. Test location update PUT /api/web/profile/location
		mockMvc.perform(put("/api/web/profile/location")
				.header("Authorization", "Bearer " + token)
				.param("latitude", "6.9271")
				.param("longitude", "79.8612"))
				.andExpect(status().isOk());
	}
}
