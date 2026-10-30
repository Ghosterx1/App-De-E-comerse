package com.example.employee_database.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.example.employee_database.entity.EmployeeEntity;
import com.example.employee_database.repository.EmployeeRepository;

@Service
public class EmployeeService {

    private final EmployeeRepository employeeRepository;

    public EmployeeService(EmployeeRepository employeeRepository) {
        this.employeeRepository = employeeRepository;
    }

    public List<EmployeeEntity> getEmployees() {
        return employeeRepository.findAll();
    }
}
