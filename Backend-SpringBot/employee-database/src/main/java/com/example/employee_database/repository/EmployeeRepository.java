package com.example.employee_database.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.employee_database.entity.EmployeeEntity;

@Repository 
public interface EmployeeRepository extends JpaRepository<EmployeeEntity, Integer> {
}
