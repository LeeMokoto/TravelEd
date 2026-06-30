import 'package:intl/intl.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/data/trip_data.dart';
import 'package:wonders/logic/trips_logic.dart';

/// Bottom sheet to create a new trip or edit an existing one's title and dates.
/// Pass [existing] to edit; omit it to create. Saves via [TripsLogic] and pops.
class TripEditorSheet extends StatefulWidget {
  const TripEditorSheet({super.key, this.existing});
  final Trip? existing;

  bool get isEditing => existing != null;

  @override
  State<TripEditorSheet> createState() => _TripEditorSheetState();
}

class _TripEditorSheetState extends State<TripEditorSheet> {
  late final _titleController = TextEditingController(text: widget.existing?.title ?? '');
  DateTimeRange? _dates;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null && t.hasDates) {
      _dates = DateTimeRange(
        start: DateTime.fromMillisecondsSinceEpoch(t.startDateMs!),
        end: DateTime.fromMillisecondsSinceEpoch(t.endDateMs!),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _dates,
    );
    if (range != null) setState(() => _dates = range);
  }

  void _handleSave() {
    if (!_canSave) return;
    final title = _titleController.text.trim();
    final startMs = _dates?.start.millisecondsSinceEpoch;
    final endMs = _dates?.end.millisecondsSinceEpoch;
    final existing = widget.existing;
    if (existing == null) {
      tripsLogic.create(title: title, startDateMs: startMs, endDateMs: endMs);
    } else {
      var updated = existing.copyWith(title: title, startDateMs: startMs, endDateMs: endMs);
      if (_dates == null) updated = updated.withClearedDates();
      tripsLogic.update(updated);
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dates == null
        ? $strings.tripsEditorSetDates
        : '${DateFormat.yMMMd().format(_dates!.start)}  –  ${DateFormat.yMMMd().format(_dates!.end)}';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all($styles.insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isEditing ? $strings.tripsEditorEditTitle : $strings.tripsEditorNewTitle,
                style: $styles.text.h3.copyWith(color: $styles.colors.offWhite),
              ),
              Gap($styles.insets.md),
              TextField(
                controller: _titleController,
                autofocus: !widget.isEditing,
                textCapitalization: TextCapitalization.words,
                cursorColor: $styles.colors.accent1,
                style: $styles.text.body.copyWith(color: $styles.colors.offWhite),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: $strings.tripsEditorNameHint,
                  hintStyle: $styles.text.body.copyWith(color: $styles.colors.greyMedium),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: $styles.colors.greyMedium)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: $styles.colors.accent1)),
                ),
              ),
              Gap($styles.insets.md),
              AppBtn.basic(
                onPressed: _pickDates,
                semanticLabel: $strings.tripsEditorSetDates,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: $styles.insets.sm, vertical: $styles.insets.sm),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular($styles.corners.md),
                    border: Border.all(color: $styles.colors.greyMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: $styles.colors.accent1, size: 18),
                      Gap($styles.insets.sm),
                      Expanded(
                        child: Text(dateLabel, style: $styles.text.bodySmall.copyWith(color: $styles.colors.offWhite)),
                      ),
                      if (_dates != null)
                        AppBtn.basic(
                          onPressed: () => setState(() => _dates = null),
                          semanticLabel: $strings.tripsEditorClearDates,
                          child: Icon(Icons.close, color: $styles.colors.greyMedium, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              Gap($styles.insets.lg),
              AppBtn.from(
                text: widget.isEditing ? $strings.tripsEditorSave : $strings.tripsEditorCreate,
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
}
