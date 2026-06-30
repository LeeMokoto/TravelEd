part of '../saved_places_screen.dart';

/// A lightweight form for adding a place by hand. Map/search-based discovery
/// (build step C) will save places the same way, via [PlacesLogic.addNew].
class _AddPlaceSheet extends StatefulWidget {
  const _AddPlaceSheet();

  @override
  State<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<_AddPlaceSheet> {
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _noteController = TextEditingController();
  PlaceKind _kind = PlaceKind.sight;

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  void _handleSave() {
    if (!_canSave) return;
    placesLogic.addNew(
      name: _nameController.text.trim(),
      country: _countryController.text.trim(),
      kind: _kind,
      note: _noteController.text.trim(),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all($styles.insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                $strings.savedPlacesSheetTitle,
                style: $styles.text.h3.copyWith(color: $styles.colors.offWhite),
              ),
              Gap($styles.insets.md),
              _Field(controller: _nameController, hint: $strings.savedPlacesFieldName, autofocus: true),
              Gap($styles.insets.sm),
              _Field(controller: _countryController, hint: $strings.savedPlacesFieldCountry),
              Gap($styles.insets.sm),
              _Field(controller: _noteController, hint: $strings.savedPlacesFieldNote),
              Gap($styles.insets.md),
              Text(
                $strings.savedPlacesKindLabel,
                style: $styles.text.bodySmallBold.copyWith(color: $styles.colors.accent2),
              ),
              Gap($styles.insets.xs),
              Wrap(
                spacing: $styles.insets.xs,
                runSpacing: $styles.insets.xs,
                children: PlaceKind.values.map((k) => _KindChip(
                      kind: k,
                      selected: k == _kind,
                      onTap: () => setState(() => _kind = k),
                    )).toList(),
              ),
              Gap($styles.insets.lg),
              AppBtn.from(
                text: $strings.savedPlacesSheetSave,
                expand: true,
                isSecondary: true,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint, this.autofocus = false});
  final TextEditingController controller;
  final String hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.words,
      cursorColor: $styles.colors.accent1,
      style: $styles.text.body.copyWith(color: $styles.colors.offWhite),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: $styles.text.body.copyWith(color: $styles.colors.greyMedium),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: $styles.colors.greyMedium)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: $styles.colors.accent1)),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind, required this.selected, required this.onTap});
  final PlaceKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? $styles.colors.white : $styles.colors.accent2;
    return AppBtn.basic(
      onPressed: onTap,
      semanticLabel: kind.label,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: $styles.insets.sm, vertical: $styles.insets.xs),
        decoration: BoxDecoration(
          color: selected ? $styles.colors.accent1 : Colors.transparent,
          borderRadius: BorderRadius.circular($styles.corners.md),
          border: Border.all(color: selected ? $styles.colors.accent1 : $styles.colors.greyMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(kind.icon, color: fg, size: 16),
            Gap($styles.insets.xs),
            Text(kind.label, style: $styles.text.bodySmall.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
