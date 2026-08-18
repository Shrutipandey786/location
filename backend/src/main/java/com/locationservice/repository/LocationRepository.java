package com.locationservice.repository;

import com.locationservice.entity.Location;
import com.locationservice.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface LocationRepository extends JpaRepository<Location, Long> {
    Optional<Location> findTopByUserOrderByUpdatedAtDesc(User user);
}
