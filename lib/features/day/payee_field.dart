import 'package:flutter/material.dart';
import 'package:io/core/theme/app_theme.dart';
import 'package:io/di.dart' as di;

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
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsViewOpenDirection: OptionsViewOpenDirection.up,
      optionsBuilder: (value) {
        final text = value.text.trim().toLowerCase();
        return di.transactionsController
            .payeeSuggestions(value.text)
            .where((o) => o.trim().toLowerCase() != text);
      },
      fieldViewBuilder:
          (context, textController, fieldFocusNode, onFieldSubmitted) {
            return TextField(
              controller: textController,
              focusNode: fieldFocusNode,
              textCapitalization: TextCapitalization.words,
              textInputAction: textInputAction,
              maxLines: 1,
              onSubmitted: (v) {
                onFieldSubmitted();
                onSubmitted?.call(v);
              },
              decoration: decoration.copyWith(
                suffixIcon: IconButton(
                  visualDensity: .compact,
                  onPressed: () {
                    if (controller.text.isEmpty) {
                      fieldFocusNode.unfocus();
                    } else {
                      controller.clear();
                    }
                  },
                  icon: const Icon(Icons.close, size: 20, color: kInkSecondary),
                ),
              ),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList();
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.white,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadius),
              side: const BorderSide(color: kBorder, width: 1),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 188, maxWidth: 320),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (context, i) => ListTile(
                  visualDensity: .comfortable,
                  leading: const Icon(
                    Icons.history,
                    size: 18,
                    color: kInkMuted,
                  ),
                  title: Text(list[i]),
                  onTap: () => onSelected(list[i]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
