import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/validators.dart';
import '../../../data/mock/demo_media.dart';
import '../../../data/mock/mock_catalog.dart';
import '../../../models/bulk_pricing.dart';
import '../../../models/product.dart';
import '../../../models/product_image.dart';
import '../../../services/product_image_service.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_image.dart';
import '../../../shared/widgets/mazonn_text_field.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../controllers/vendor_studio_controller.dart';
import '../widgets/vendor_access_gate.dart';

class VendorProductFormScreen extends StatefulWidget {
  const VendorProductFormScreen({super.key, this.existing});
  final Product? existing;

  @override
  State<VendorProductFormScreen> createState() => _VendorProductFormScreenState();
}

class _VendorProductFormScreenState extends State<VendorProductFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late final TextEditingController _stock;
  late final TextEditingController _sku;
  late final TextEditingController _brand;
  late final TextEditingController _barcode;
  late final TextEditingController _variants;
  late final TextEditingController _sizes;
  String _category = 'fashion';
  final _form = GlobalKey<FormState>();
  final _images = ProductImageService();
  late String _productId;
  List<String> _imageUrls = [];
  List<BulkPricingRule> _tiers = [];
  double? _uploadProgress;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _productId = p?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}';
    _name = TextEditingController(text: p?.name);
    _desc = TextEditingController(text: p?.description);
    _price = TextEditingController(text: p?.price.toString());
    _discount = TextEditingController(text: p?.originalPrice?.toString() ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '10');
    _sku = TextEditingController(text: p?.sku ?? 'AN-NEW');
    _brand = TextEditingController(text: p?.brand ?? 'Atelier Noir');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _variants = TextEditingController(text: p == null ? 'Stone, Noir' : p.colors.join(', '));
    _sizes = TextEditingController(text: p?.sizes.join(', ') ?? '');
    _category = p?.categoryId ?? 'fashion';
    _imageUrls = List.of(p?.imageUrls ?? const []);
    _tiers = List.of(p?.bulkPricing ?? PricingEngine.defaultVendorTiers());
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _discount.dispose();
    _stock.dispose();
    _sku.dispose();
    _brand.dispose();
    _barcode.dispose();
    _variants.dispose();
    _sizes.dispose();
    super.dispose();
  }

  Product _build({required ProductModeration moderation, required bool active}) {
    final vendor = context.read<AuthController>().vendor;
    final price = double.tryParse(_price.text) ?? 0;
    final original = double.tryParse(_discount.text);
    return Product(
      id: _productId,
      name: _name.text,
      brand: _brand.text,
      description: _desc.text,
      categoryId: _category,
      vendorId: vendor?.id ?? MockCatalog.vendorId,
      vendorName: vendor?.businessName ?? 'Studio',
      price: price,
      originalPrice: original,
      rating: widget.existing?.rating ?? 5,
      reviewCount: widget.existing?.reviewCount ?? 0,
      stock: int.tryParse(_stock.text) ?? 0,
      sku: _sku.text,
      barcode: _barcode.text,
      visualSeed: widget.existing?.visualSeed ?? DateTime.now().millisecond,
      colors: _variants.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      sizes: _sizes.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      imageUrls: _imageUrls,
      images: ProductImage.fromUrls(productId: _productId, urls: _imageUrls, altText: _name.text.trim()),
      searchKeywords: DemoMedia.keywordsFor(
        name: _name.text,
        brand: _brand.text,
        description: _desc.text,
        categoryId: _category,
      ),
      subcategory: DemoMedia.subcategoryFor(
        name: _name.text,
        description: _desc.text,
        categoryId: _category,
      ),
      bulkPricing: _tiers,
      moderation: moderation,
      rejectionReason: moderation == ProductModeration.pending ? '' : (widget.existing?.rejectionReason ?? ''),
      isActive: active,
      vendorApprovalStatus: vendor?.approvalStatus ?? 'pending',
    );
  }

  Future<void> _save({required bool publish}) async {
    if (!_form.currentState!.validate()) return;
    if (publish && _imageUrls.isEmpty) {
      setState(() => _error = 'Add at least one product image and set a primary image before publishing.');
      return;
    }
    if (PricingEngine.rangesOverlap(_tiers)) {
      setState(() => _error = 'Bulk pricing quantity ranges cannot overlap.');
      return;
    }
    setState(() => _error = null);
    try {
      await context.read<VendorStudioController>().saveProduct(
            _build(
              moderation: publish ? ProductModeration.pending : ProductModeration.draft,
              active: publish,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e is StateError ? e.message : 'Could not save this product.');
    }
  }

  Future<void> _addImages({required bool camera}) async {
    try {
      final files = await _images.pick(camera: camera);
      for (var i = 0; i < files.length; i++) {
        setState(() => _uploadProgress = 0);
        final url = await _images.upload(
          productId: _productId,
          file: files[i],
          index: _imageUrls.length + i,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
        setState(() {
          _imageUrls = [..._imageUrls, url];
          _uploadProgress = null;
        });
      }
    } catch (e) {
      setState(() {
        _uploadProgress = null;
        _error = e is StateError ? e.message : 'Image upload failed. Check your connection and try again.';
      });
    }
  }

  void _move(int index, int delta) {
    final next = index + delta;
    if (next < 0 || next >= _imageUrls.length) return;
    setState(() {
      final url = _imageUrls.removeAt(index);
      _imageUrls.insert(next, url);
    });
  }

  Future<void> _replaceAt(int index) async {
    try {
      final files = await _images.pick(camera: false);
      if (files.isEmpty) return;
      setState(() => _uploadProgress = 0);
      final url = await _images.upload(
        productId: _productId,
        file: files.first,
        index: index,
        onProgress: (p) => setState(() => _uploadProgress = p),
      );
      setState(() {
        _imageUrls[index] = url;
        _uploadProgress = null;
      });
    } catch (e) {
      setState(() {
        _uploadProgress = null;
        _error = e is StateError ? e.message : 'Could not replace this image.';
      });
    }
  }

  void _preview(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: AspectRatio(
          aspectRatio: 1,
          child: MazonnImage(url: _imageUrls[index], seed: index, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _addTier() {
    setState(() {
      _tiers = [
        ..._tiers,
        BulkPricingRule(
          id: 't${DateTime.now().millisecondsSinceEpoch}',
          minQty: 5,
          maxQty: 9,
          discountType: DiscountType.percent,
          discountValue: 5,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<AuthController>().vendor;
    if (vendor != null && !vendor.canSell) {
      return VendorLockedScreen(vendor: vendor, feature: 'product publishing');
    }
    return Scaffold(
      appBar: MazonnAppBar(title: widget.existing == null ? 'Add product' : 'Edit product'),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('PRODUCT IMAGES', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_imageUrls.isEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: MazonnColors.cream, borderRadius: MazonnRadius.card),
                  child: const Text('No images yet — upload from gallery or camera'),
                ),
              )
            else
              SizedBox(
                height: 232,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 128,
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () => _preview(i),
                                      child: MazonnImage(url: _imageUrls[i], seed: i, borderRadius: MazonnRadius.card),
                                    ),
                                  ),
                                  if (i == 0)
                                    const Positioned(left: 6, top: 6, child: StatusChip(label: 'Primary', color: MazonnColors.goldDark)),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () => setState(() => _imageUrls.removeAt(i)),
                                      icon: const Icon(Icons.close, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  tooltip: 'Move left',
                                  onPressed: i == 0 ? null : () => _move(i, -1),
                                  icon: const Icon(Icons.chevron_left, size: 20),
                                ),
                                IconButton(
                                  tooltip: 'Replace',
                                  onPressed: () => _replaceAt(i),
                                  icon: const Icon(Icons.swap_horiz, size: 18),
                                ),
                                IconButton(
                                  tooltip: 'Move right',
                                  onPressed: i == _imageUrls.length - 1 ? null : () => _move(i, 1),
                                  icon: const Icon(Icons.chevron_right, size: 20),
                                ),
                              ],
                            ),
                            if (i != 0)
                              TextButton(
                                onPressed: () => setState(() {
                                  final url = _imageUrls.removeAt(i);
                                  _imageUrls.insert(0, url);
                                }),
                                child: const Text('Set primary'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_uploadProgress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _uploadProgress),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: MazonnButton(label: '+ Gallery', tone: MazonnButtonTone.outline, onPressed: () => _addImages(camera: false))),
                const SizedBox(width: 8),
                Expanded(child: MazonnButton(label: 'Camera', tone: MazonnButtonTone.outline, onPressed: () => _addImages(camera: true))),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.existing?.moderation == ProductModeration.rejected && (widget.existing?.rejectionReason.isNotEmpty ?? false))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: MazonnColors.cream, borderRadius: MazonnRadius.card),
                child: Text('Rejected: ${widget.existing!.rejectionReason}'),
              ),
            MazonnTextField(label: 'Product name', controller: _name, validator: (v) => MazonnValidators.requiredField(v, label: 'Name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: MockCatalog.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Description', controller: _desc, maxLines: 4),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Brand', controller: _brand),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Price', controller: _price, keyboardType: TextInputType.number, validator: MazonnValidators.price),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Original price / discount from', controller: _discount, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Stock quantity', controller: _stock, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            MazonnTextField(label: 'SKU', controller: _sku),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Barcode', controller: _barcode),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Colors / variants', controller: _variants),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Sizes', controller: _sizes),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Bulk pricing', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton(onPressed: _addTier, child: const Text('Add pricing tier')),
              ],
            ),
            ..._tiers.asMap().entries.map((entry) {
              final i = entry.key;
              final tier = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Tier ${i + 1}'),
                          const Spacer(),
                          Switch(
                            value: tier.active,
                            onChanged: (v) => setState(() => _tiers[i] = tier.copyWith(active: v)),
                          ),
                          IconButton(onPressed: () => setState(() => _tiers.removeAt(i)), icon: const Icon(Icons.delete_outline)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '${tier.minQty}',
                              decoration: const InputDecoration(labelText: 'Min qty'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => _tiers[i] = tier.copyWith(minQty: int.tryParse(v) ?? tier.minQty),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: tier.maxQty?.toString() ?? '',
                              decoration: const InputDecoration(labelText: 'Max qty'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => _tiers[i] = tier.copyWith(
                                maxQty: int.tryParse(v),
                                clearMax: v.trim().isEmpty,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: '${tier.discountValue}',
                              decoration: InputDecoration(labelText: tier.discountType == DiscountType.percent ? '% off' : 'Amount off'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => _tiers[i] = tier.copyWith(discountValue: double.tryParse(v) ?? tier.discountValue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_error != null) MazonnErrorText(_error),
            const SizedBox(height: 12),
            MazonnButton(label: 'Save draft', tone: MazonnButtonTone.outline, onPressed: () => _save(publish: false)),
            const SizedBox(height: 10),
            MazonnButton(label: widget.existing?.moderation == ProductModeration.rejected ? 'Resubmit for approval' : 'Submit / Publish', onPressed: () => _save(publish: true)),
          ],
        ),
      ),
    );
  }

}