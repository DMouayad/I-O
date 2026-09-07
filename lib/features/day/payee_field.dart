import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../di.dart' as di;

class PayeeField extends StatelessWidget {
  const PayeeField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.decoration,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final InputDecoration decoration;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;

    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsViewOpenDirection: OptionsViewOpenDirection.up,
      optionsBuilder: (value) {
        final text = value.text.trim().toLowerCase();
        if (text.isEmpty) return const Iterable<String>.empty();
        return di.transactionsController
            .payeeSuggestions(value.text)
            .where((o) => o.trim().toLowerCase() != text);
      },
      fieldViewBuilder:
          (context, textController, fieldFocusNode, onFieldSubmitted) {
            return ListenableBuilder(
              listenable: textController,
              builder: (context, _) {
                final hasText = textController.text.isNotEmpty;
                return TextField(
                  controller: textController,
                  focusNode: fieldFocusNode,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: textInputAction,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: pal.text,
                  ),
                  onSubmitted: (v) {
                    onFieldSubmitted();
                    onSubmitted?.call(v);
                  },
                  decoration: decoration.copyWith(
                    suffixIcon: hasText
                        ? IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                            onPressed: () => textController.clear(),
                            icon: Icon(
                              Icons.cancel,
                              size: 16,
                              color: pal.textMuted,
                            ),
                          )
                        : null,
                  ),
                );
              },
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList();

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 360),
            decoration: BoxDecoration(
              color: pal.surfaceHigh,
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(color: pal.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kRadius),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: pal.border.withValues(alpha: 0.4),
                ),
                itemBuilder: (context, i) {
                  final item = list[i];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelected(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 16,
                              color: pal.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: pal.text,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.north_west_rounded,
                              size: 14,
                              color: pal.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
