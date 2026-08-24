import 'product.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    this.selectedColor,
    this.selectedSize,
  });

  final Product product;
  final int quantity;
  final String? selectedColor;
  final String? selectedSize;

  double get lineTotal => product.price * quantity;

  String get variantKey => '${product.id}|${selectedColor ?? ''}|${selectedSize ?? ''}';

  CartItem copyWith({int? quantity, String? selectedColor, String? selectedSize}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
        'selectedColor': selectedColor,
        'selectedSize': selectedSize,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        quantity: json['quantity'] as int,
        selectedColor: json['selectedColor'] as String?,
        selectedSize: json['selectedSize'] as String?,
      );
}
