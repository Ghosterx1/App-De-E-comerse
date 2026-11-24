package com.example.employeedb.cart.dto;

import java.math.BigDecimal;
import java.util.List;

/** Respuesta del carrito con sus ítems y total. */
public record CartResponse(
        Long id,
        Long userId,
        List<CartItemResponse> items,
        BigDecimal total) {
}
