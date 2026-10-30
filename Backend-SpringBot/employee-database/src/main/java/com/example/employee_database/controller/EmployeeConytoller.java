package com.example.employee_database.controller;

import org.springframework.web.bind.annotation.*;
import java.util.List;

import com.example.employee_database.entity.EmployeeEntity;
import com.example.employee_database.service.EmployeeService;

@RestController 
@RequestMapping ("/api/employees")
@CrossOrigin (origins = "*")
public class EmployeeConytoller {

    private final EmployeeService employeeService;

    public EmployeeConytoller(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    @GetMapping
    public List<EmployeeEntity> getEmployees() {
        return employeeService.getEmployees();
    }
}
