package com.locationservice.repository;

import com.locationservice.entity.Activity;
import com.locationservice.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ActivityRepository extends JpaRepository<Activity, Long> {

    List<Activity> findByUserOrderByCreatedAtDesc(User user);

    List<Activity> findByUserAndTypeOrderByCreatedAtDesc(User user, String type);
}
