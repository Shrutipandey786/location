package com.locationservice.controller;

import com.locationservice.dto.LoginRequest;
import com.locationservice.dto.LoginResponse;
import com.locationservice.dto.RegisterRequest;
import com.locationservice.dto.RegisterResponse;
import com.locationservice.dto.UserResponse;
import com.locationservice.entity.RefreshToken;
import com.locationservice.entity.User;
import com.locationservice.exception.TokenRefreshException;
import com.locationservice.service.AuthService;
import com.locationservice.service.RefreshTokenService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final RefreshTokenService refreshTokenService;

    public AuthController(AuthService authService, RefreshTokenService refreshTokenService) {
        this.authService = authService;
        this.refreshTokenService = refreshTokenService;
    }

    @PostMapping("/register")
    public ResponseEntity<RegisterResponse> register(@Valid @RequestBody RegisterRequest request) {
        RegisterResponse response = authService.register(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        User user = authService.authenticate(request);
        RefreshToken refreshToken = refreshTokenService.createRefreshToken(user);

        ResponseCookie accessCookie = authService.createAccessTokenCookie(user);
        ResponseCookie refreshCookie = authService.createRefreshTokenCookie(refreshToken);

        LoginResponse response = new LoginResponse(
                "Login successful",
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getRole());

        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, accessCookie.toString())
                .header(HttpHeaders.SET_COOKIE, refreshCookie.toString())
                .body(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<Map<String, String>> refreshToken(
            @CookieValue(name = "refresh_token", required = false) String refreshTokenFromCookie,
            HttpServletRequest request) {

        String token = refreshTokenFromCookie;
        if ((token == null || token.isBlank()) && request.getCookies() != null) {
            for (Cookie cookie : request.getCookies()) {
                if ("refresh_token".equals(cookie.getName())) {
                    token = cookie.getValue();
                    break;
                }
            }
        }

        if (token == null || token.isBlank()) {

            throw new TokenRefreshException("Refresh token is missing. Please sign in again.");
        }

        RefreshToken refreshToken = refreshTokenService.findByToken(token)
                .orElseThrow(() -> new TokenRefreshException("Refresh token not found. Please sign in again."));

        refreshTokenService.verifyExpiration(refreshToken);
        User user = refreshToken.getUser();

        // Rotate Refresh Token & Issue New Access Token
        RefreshToken newRefreshToken = refreshTokenService.createRefreshToken(user);
        ResponseCookie newAccessCookie = authService.createAccessTokenCookie(user);
        ResponseCookie newRefreshCookie = authService.createRefreshTokenCookie(newRefreshToken);

        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, newAccessCookie.toString())
                .header(HttpHeaders.SET_COOKIE, newRefreshCookie.toString())
                .body(Map.of("message", "Token refreshed successfully"));
    }

    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(
            @CookieValue(name = "refresh_token", required = false) String refreshTokenFromCookie,
            Authentication authentication) {

        if (refreshTokenFromCookie != null && !refreshTokenFromCookie.isBlank()) {
            refreshTokenService.deleteByToken(refreshTokenFromCookie);
        } else if (authentication != null && authentication.getPrincipal() instanceof User user) {
            refreshTokenService.deleteByUser(user);
        }

        ResponseCookie deleteAccessCookie = authService.createLogoutAccessCookie();
        ResponseCookie deleteRefreshCookie = authService.createLogoutRefreshCookie();

        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, deleteAccessCookie.toString())
                .header(HttpHeaders.SET_COOKIE, deleteRefreshCookie.toString())
                .body(Map.of("message", "Logged out successfully"));
    }

    @GetMapping("/me")
    public ResponseEntity<UserResponse> getCurrentUser(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        UserResponse response = new UserResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getRole());
        return ResponseEntity.ok(response);
    }
}