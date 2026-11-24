package com.example.employeedb.cart.repository;

import com.example.employeedb.cart.entity.CartItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CartItemRepository extends JpaRepository<CartItem, Long> {

    boolean existsByCartIdAndProductId(Long cartId, Long productId);
}
