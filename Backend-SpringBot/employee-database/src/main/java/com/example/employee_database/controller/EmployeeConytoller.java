package com.example.employee_database.controller;

import org.springframework.web.bind.annotation.*;
import java.util.List;


@RestController 
@RequestMapping ("/api/employees")
@CrossOrigin (origins = "*")
public class EmployeeConytoller {


    @GetMapping 
    public List<String>getEmployees(){
        return List.of("Juan", "Maria", "Carlos");
    }
}
