part of '../map_discovery_screen.dart';

/// Sheet to name a pinned location and save it as a [Place]. Pre-filled when the
/// pin came from a search result; blank when dropped by tapping the map.
class _SavePinSheet extends StatefulWidget {
  const _SavePinSheet({required this.position, this.initialName = '', this.initialCountry = ''});
  final LatLng position;
  final String initialName;
  final String initialCountry;

  @override
  State<_SavePinSheet> createState() => _SavePinSheetState();
}

class _SavePinSheetState extends State<_SavePinSheet> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _countryController = TextEditingController(text: widget.initialCountry);
  PlaceKind _kind = PlaceKind.sight;

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  void _handleSave() {
    if (!_canSave) return;
    placesLogic.addNew(
      name: _nameController.text.trim(),
      country: _countryController.text.trim(),
      lat: widget.position.latitude,
      lng: widget.position.longitude,
      kind: _kind,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all($styles.insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text($strings.discoverSaveTitle, style: $styles.text.h3.copyWith(color: $styles.colors.offWhite)),
              Gap($styles.insets.xs),
              Text(
                _formatLatLng(widget.position),
                style: $styles.text.caption.copyWith(color: $styles.colors.greyMedium),
              ),
              Gap($styles.insets.md),
              _field(_nameController, $strings.savedPlacesFieldName, autofocus: widget.initialName.isEmpty),
              Gap($styles.insets.sm),
              _field(_countryController, $strings.savedPlacesFieldCountry),
              Gap($styles.insets.md),
              Text($strings.savedPlacesKindLabel,
                  style: $styles.text.bodySmallBold.copyWith(color: $styles.colors.accent2)),
              Gap($styles.insets.xs),
              Wrap(
                spacing: $styles.insets.xs,
                runSpacing: $styles.insets.xs,
                children: PlaceKind.values
                    .map((k) => _KindChip(kind: k, selected: k == _kind, onTap: () => setState(() => _kind = k)))
                    .toList(),
              ),
              Gap($styles.insets.lg),
              AppBtn.from(
                text: $strings.discoverSave,
                expand: true,
                isSecondary: true,
                onPressed: _canSave ? _handleSave : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, {bool autofocus = false}) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.words,
      cursorColor: $styles.colors.accent1,
      style: $styles.text.body.copyWith(color: $styles.colors.offWhite),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: $styles.text.body.copyWith(color: $styles.colors.greyMedium),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: $styles.colors.greyMedium)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: $styles.colors.accent1)),
      ),
    );
  }

  static String _formatLatLng(LatLng p) =>
      '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
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
