package com.example.employeedb.cart.service;

import com.example.employeedb.auth.entity.User;
import com.example.employeedb.auth.repository.UserRepository;
import com.example.employeedb.cart.dto.AddCartItemRequest;
import com.example.employeedb.cart.dto.CartResponse;
import com.example.employeedb.cart.entity.Cart;
import com.example.employeedb.cart.entity.CartItem;
import com.example.employeedb.cart.repository.CartItemRepository;
import com.example.employeedb.cart.repository.CartRepository;
import com.example.employeedb.product.Product;
import com.example.employeedb.product.ProductRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;

    public CartService(CartRepository cartRepository,
                       CartItemRepository cartItemRepository,
                       ProductRepository productRepository,
                       UserRepository userRepository) {
        this.cartRepository = cartRepository;
        this.cartItemRepository = cartItemRepository;
        this.productRepository = productRepository;
        this.userRepository = userRepository;
    }

    /**
     * Obtiene el carrito del usuario autenticado o lo crea si no existe.
     */
    public CartResponse getCurrentUserCart() {
        String email = getCurrentUserEmail();
        Cart cart = cartRepository.findByUserId(getUserIdByEmail(email))
                .orElseGet(() -> cartRepository.save(new Cart(getUserIdByEmail(email))));
        return mapToResponse(cart);
    }

    /**
     * Agrega un producto al carrito o incrementa su cantidad si ya existe.
     */
    @Transactional
    public CartResponse addItem(AddCartItemRequest request) {
        String email = getCurrentUserEmail();
        Long userId = getUserIdByEmail(email);

        Cart cart = cartRepository.findByUserId(userId)
                .orElseGet(() -> cartRepository.save(new Cart(userId)));

        Product product = productRepository.findById(request.productId())
                .orElseThrow(() -> new RuntimeException("Producto no encontrado con id " + request.productId()));

        if (product.getStock() < request.quantity()) {
            throw new RuntimeException("Stock insuficiente para el producto " + product.getName() +
                    ". Disponible: " + product.getStock());
        }

        CartItem existing = cart.getItems().stream()
                .filter(item -> item.getProductId().equals(request.productId()))
                .findFirst()
                .orElse(null);

        if (existing != null) {
            int newQuantity = existing.getQuantity() + request.quantity();
            if (product.getStock() < newQuantity) {
                throw new RuntimeException("Stock insuficiente. Total solicitado: " + newQuantity +
                        ", disponible: " + product.getStock());
            }
            existing.setQuantity(newQuantity);
            cartItemRepository.save(existing);
        } else {
            CartItem item = new CartItem(
                    cart,
                    product.getId(),
                    product.getName(),
                    request.quantity(),
                    product.getPrice()
            );
            cart.getItems().add(item);
            cartItemRepository.save(item);
        }

        return mapToResponse(cart);
    }

    /**
     * Actualiza la cantidad de un ítem en el carrito.
     */
    @Transactional
    public CartResponse updateQuantity(Long productId, int quantity) {
        if (quantity < 1) {
            throw new RuntimeException("La cantidad debe ser al menos 1.");
        }

        String email = getCurrentUserEmail();
        Long userId = getUserIdByEmail(email);

        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Carrito no encontrado."));

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Producto no encontrado con id " + productId));

        if (product.getStock() < quantity) {
            throw new RuntimeException("Stock insuficiente para el producto " + product.getName() +
                    ". Disponible: " + product.getStock());
        }

        CartItem item = cart.getItems().stream()
                .filter(i -> i.getProductId().equals(productId))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("El producto no está en el carrito."));

        item.setQuantity(quantity);
        cartItemRepository.save(item);

        return mapToResponse(cart);
    }

    /**
     * Elimina un producto del carrito.
     */
    @Transactional
    public CartResponse removeItem(Long productId) {
        String email = getCurrentUserEmail();
        Long userId = getUserIdByEmail(email);

        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Carrito no encontrado."));

        CartItem item = cart.getItems().stream()
                .filter(i -> i.getProductId().equals(productId))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("El producto no está en el carrito."));

        cart.getItems().remove(item);
        cartItemRepository.delete(item);

        return mapToResponse(cart);
    }

    /**
     * Vacía el carrito del usuario autenticado.
     */
    @Transactional
    public void clearCart() {
        String email = getCurrentUserEmail();
        Long userId = getUserIdByEmail(email);

        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Carrito no encontrado."));

        cartItemRepository.deleteAll(cart.getItems());
        cart.getItems().clear();
    }

    /* ------------------------------------------------------------------ */

    private String getCurrentUserEmail() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }

    private Long getUserIdByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado con email: " + email));
        return user.getId();
    }

    private CartResponse mapToResponse(Cart cart) {
        List<CartItemResponse> itemResponses = cart.getItems().stream()
                .map(item -> new CartItemResponse(
                        item.getProductId(),
                        item.getProductName(),
                        item.getQuantity(),
                        item.getPrice(),
                        item.getSubtotal()
                ))
                .collect(Collectors.toList());

        BigDecimal total = itemResponses.stream()
                .map(CartItemResponse::subtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new CartResponse(cart.getId(), cart.getUserId(), itemResponses, total);
    }
}
