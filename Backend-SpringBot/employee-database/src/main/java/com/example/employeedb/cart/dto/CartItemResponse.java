package com.example.employeedb.cart.dto;

import java.math.BigDecimal;

/** Ítem del carrito tal como se devuelve al cliente. */
public record CartItemResponse(
        Long productId,
        String productName,
        int quantity,
        BigDecimal price,
        BigDecimal subtotal) {
}
