import 'dart:developer';

import 'package:flutter/material.dart';

class SelectOptions extends StatelessWidget {
  const SelectOptions({super.key, required this.options});

  final Map<String, VoidCallback> options;

  @override
  Widget build(BuildContext context) {
    final callback = options.values.toList();
    final titles = options.keys.toList();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: ListView.separated(
              itemCount: options.length + 1,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return index == 0
                    ? Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        child: Text(
                          'Select option',
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: const Color(0xFF8F8F8F),
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: index != 0 ? callback[index - 1] : null,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            index != 0 ? titles[index - 1] : '',
                            style: theme.textTheme.bodyLarge!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
              },
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              fixedSize: const Size.fromHeight(60),
              textStyle: theme.textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              )),
          onPressed: () {
            log('close the selection dialog');
            //If the root navigator contains the bottom dialog, close it right away
            if (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          child: Text('Close',
              style: theme.textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              )),
        ),
      ],
    );
  }
}
