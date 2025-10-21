import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final CategoryModel? category;
  final String userId;
  const AddEditCategoryScreen({super.key, this.category, required this.userId});

  @override
  ConsumerState<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _budgetController;

  late Color _selectedColor;
  late IconData _selectedIcon;
  bool _isSaving = false;

  final List<Color> availableColors = [
    Colors.indigo,
    Colors.teal,
    Colors.orange,
    Colors.redAccent,
    Colors.green,
    Colors.deepPurple,
    Colors.blueGrey,
  ];

  final List<IconData> availableIcons = [
    Icons.fastfood,
    Icons.home,
    Icons.shopping_bag,
    Icons.directions_bus,
    Icons.health_and_safety,
    Icons.savings,
    Icons.local_movies,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _budgetController = TextEditingController(text: widget.category?.budget.toString() ?? '');
    _selectedColor = widget.category?.color ?? Colors.indigo;
    _selectedIcon = widget.category?.icon ?? Icons.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    print("user id: ${widget.userId}");
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(categoryNotifierProvider(widget.userId).notifier);

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final categoryModel = CategoryModel(
      id: widget.category?.id ?? "cat_${now.millisecondsSinceEpoch}",
      userId: widget.userId,
      name: _nameController.text.trim(),
      budget: int.parse(_budgetController.text.trim()),
      color: _selectedColor,
      icon: _selectedIcon,
      createdAt: widget.category?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (widget.category == null) {
        await notifier.addCategory(categoryModel);
      } else {
        await notifier.updateCategory(categoryModel);
      }

      if (mounted) Navigator.pop(context, categoryModel);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save category: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == null ? "Add Category" : "Edit Category",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Category Name",
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (val) => val!.isEmpty ? "Enter a name" : null,
              ),
              const SizedBox(height: 16),

              // Budget
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Monthly Budget",
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (val) => val!.isEmpty ? "Enter budget" : null,
              ),
              const SizedBox(height: 24),

              // Color picker
              Text(
                "Choose Color",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: availableColors
                    .map(
                      (color) => GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Icon picker
              Text(
                "Choose Icon",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: availableIcons
                    .map(
                      (icon) => GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _selectedIcon == icon ? _selectedColor.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedIcon == icon ? _selectedColor : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: _selectedIcon == icon ? _selectedColor : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: _isSaving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check),
                  label: Text(
                    widget.category == null ? "Add Category" : "Update Category",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: _isSaving ? null : _saveCategory,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
