package com.example.employeedb.cart.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/** Datos para agregar un ítem al carrito. */
public record AddCartItemRequest(
        @NotNull(message = "El ID del producto es obligatorio.")
        Long productId,

        @Min(value = 1, message = "La cantidad debe ser al menos 1.")
        int quantity) {
}
