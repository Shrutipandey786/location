package com.locationservice.service;

import com.locationservice.dto.LoginRequest;
import com.locationservice.dto.RegisterRequest;
import com.locationservice.dto.RegisterResponse;
import com.locationservice.entity.RefreshToken;
import com.locationservice.entity.User;
import com.locationservice.repository.UserRepository;
import com.locationservice.security.JwtService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseCookie;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;

    @Value("${security.cookie.secure:false}")
    private boolean cookieSecure;

    @Value("${security.cookie.same-site:Lax}")
    private String cookieSameSite;

    @Value("${security.cookie.access-max-age-seconds:900}")
    private long accessCookieMaxAgeSeconds;

    @Value("${security.cookie.refresh-max-age-seconds:604800}")
    private long refreshCookieMaxAgeSeconds;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       RefreshTokenService refreshTokenService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.refreshTokenService = refreshTokenService;
    }

    @Transactional
    public RegisterResponse register(RegisterRequest request) {
        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new IllegalArgumentException("Password and confirm password do not match");
        }

        String normalizedEmail = request.getEmail().trim().toLowerCase();

        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new IllegalArgumentException("An account with this email already exists");
        }

        User user = new User();
        user.setName(request.getName().trim());
        user.setEmail(normalizedEmail);
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setRole("USER"); // Backend controlled role assignment

        User savedUser = userRepository.save(user);

        return new RegisterResponse(
                "Account created successfully",
                savedUser.getId(),
                savedUser.getName(),
                savedUser.getEmail());
    }

    public User authenticate(LoginRequest request) {
        String normalizedEmail = request.getEmail().trim().toLowerCase();

        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BadCredentialsException("Invalid email or password");
        }

        return user;
    }

    public ResponseCookie createAccessTokenCookie(User user) {
        String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole());

        return ResponseCookie.from("access_token", token)
                .httpOnly(true)
                .secure(cookieSecure)
                .path("/")
                .maxAge(accessCookieMaxAgeSeconds)
                .sameSite(cookieSameSite)
                .build();
    }

    public ResponseCookie createRefreshTokenCookie(RefreshToken refreshToken) {
        return ResponseCookie.from("refresh_token", refreshToken.getToken())
                .httpOnly(true)
                .secure(cookieSecure)
                .path("/")
                .maxAge(refreshCookieMaxAgeSeconds)
                .sameSite(cookieSameSite)
                .build();
    }

    public ResponseCookie createLogoutAccessCookie() {
        return ResponseCookie.from("access_token", "")
                .httpOnly(true)
                .secure(cookieSecure)
                .path("/")
                .maxAge(0)
                .sameSite(cookieSameSite)
                .build();
    }

    public ResponseCookie createLogoutRefreshCookie() {
        return ResponseCookie.from("refresh_token", "")
                .httpOnly(true)
                .secure(cookieSecure)
                .path("/")
                .maxAge(0)
                .sameSite(cookieSameSite)
                .build();
    }
}