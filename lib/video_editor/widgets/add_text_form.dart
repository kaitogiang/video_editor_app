import 'dart:developer';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

class AddTextForm extends StatefulWidget {
  const AddTextForm({super.key});

  @override
  State<AddTextForm> createState() => _AddTextFormState();
}

class _AddTextFormState extends State<AddTextForm> {
  Color dialogPickerColor = Colors.white;
  Color dialogSelectColor = Colors.white;
  final fontFamilyList = [
    'HelveticaNeueBlack',
    'Times New Roman',
    'Arial',
    'Garamond',
    'BrushyScript',
    'Vantgard',
    'Graceful',
    'Manuscript',
    'Rosalin',
    'Mystiqua',
    'Moaze',
    'Delphine',
    'Galter',
  ];
  //Store the current selected color for the text
  final ValueNotifier<Color> _selectedColor =
      ValueNotifier<Color>(Colors.white);
  //Store the current selected fontFamily
  final ValueNotifier<String> _selectedFontFamily =
      ValueNotifier<String>('HelveticaNeueBlack');
  //Store the current typed Text
  final ValueNotifier<String> _typedText = ValueNotifier<String>('');
  //Store the combination of the three value above
  final ValueNotifier<Map<String, dynamic>> _displayedText =
      ValueNotifier<Map<String, dynamic>>({});

  Future<bool> colorPickerDialog() async {
    return ColorPicker(
      // Use the dialogPickerColor as start and active color.
      color: dialogPickerColor,
      // Update the dialogPickerColor using the callback.
      onColorChanged: (Color color) =>
          setState(() => dialogPickerColor = color),
      actionButtons: const ColorPickerActionButtons(
        okButton: true,
        closeButton: true,
        dialogActionButtons: false,
      ),
      width: 50,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        'Select color',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subheading: Text(
        'Select color shade',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      wheelSubheading: Text(
        'Selected color and its shades',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.wheel: true,
        ColorPickerType.accent: false,
        ColorPickerType.both: false,
        ColorPickerType.custom: false,
        ColorPickerType.primary: false,
      },
      // customColorSwatchesAndNames: colorsNameMap,
    ).showPickerDialog(
      context,
      // New in version 3.0.0 custom transitions support.
      transitionBuilder: (BuildContext context, Animation<double> a1,
          Animation<double> a2, Widget widget) {
        final double curvedValue =
            Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: widget,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      constraints:
          const BoxConstraints(minHeight: 460, minWidth: 300, maxWidth: 320),
    );
  }

  Map<String, dynamic> _createText(
      String text, String fontFamily, Color color) {
    return {
      'text': text,
      'fontFamily': fontFamily,
      'color': color,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyleList = [
      const TextStyle(
        fontSize: 15,
        fontFamily: 'HelveticaNeueBlack',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'Times New Roman',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'Arial',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'Garamond',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'BrushyScript',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'Vantgard',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'Graceful',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'Manuscript',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'Rosalin',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'Mystiqua',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'Moaze',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'Delphine',
        color: Colors.white,
      ),
      const TextStyle(
        fontSize: 15,
        fontFamily: 'Galter',
        color: Colors.white,
      ),
    ];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //Color picker and Done button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Color picker Button
                ValueListenableBuilder(
                    valueListenable: _selectedColor,
                    builder: (context, selectedColor, child) {
                      return ColorIndicator(
                          width: 40,
                          height: 40,
                          borderRadius: 5,
                          color: selectedColor,
                          elevation: 1,
                          onSelectFocus: false,
                          onSelect: () async {
                            // Wait for the dialog to return color selection result.
                            final Color newColor = await showColorPickerDialog(
                              // The dialog needs a context, we pass it in.
                              context,
                              // We use the dialogSelectColor, as its starting color.
                              dialogSelectColor,
                              title: Text('Select color',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .copyWith(
                                        color: Colors.white,
                                      )),
                              width: 40,
                              height: 40,
                              spacing: 0,
                              runSpacing: 0,
                              borderRadius: 0,
                              wheelDiameter: 165,
                              enableOpacity: true,
                              showColorCode: true,
                              colorCodeHasColor: true,

                              pickersEnabled: <ColorPickerType, bool>{
                                ColorPickerType.wheel: true,
                                ColorPickerType.accent: false,
                                ColorPickerType.primary: false,
                              },
                              actionButtons: const ColorPickerActionButtons(
                                okButton: true,
                                closeButton: true,
                                dialogActionButtons: false,
                              ),
                              transitionBuilder: (BuildContext context,
                                  Animation<double> a1,
                                  Animation<double> a2,
                                  Widget widget) {
                                final double curvedValue =
                                    Curves.easeInOutBack.transform(a1.value) -
                                        1.0;
                                return Transform(
                                  transform: Matrix4.translationValues(
                                      0.0, curvedValue * 200, 0.0),
                                  child: Opacity(
                                    opacity: a1.value,
                                    child: widget,
                                  ),
                                );
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                              constraints: const BoxConstraints(
                                  minHeight: 480, minWidth: 320, maxWidth: 320),
                            );
                            //Save the selected color
                            _selectedColor.value = newColor;
                            //create the object to display the text in the UI
                            final newText = _createText(
                                _typedText.value,
                                _selectedFontFamily.value,
                                _selectedColor.value);
                            _displayedText.value = newText;
                          });
                    }),
                //showing the Done button
                ValueListenableBuilder(
                    valueListenable: _displayedText,
                    builder: (context, displayedText, child) {
                      return TextButton(
                        style: TextButton.styleFrom(
                          disabledForegroundColor: const Color(0xFF686868),
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        onPressed: displayedText.isEmpty ||
                                (displayedText['text'] as String).isEmpty
                            ? null
                            : () {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              },
                        child: const Text(
                          'Done',
                        ),
                      );
                    }),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ValueListenableBuilder(
                    valueListenable: _displayedText,
                    builder: (context, value, child) {
                      return value.isEmpty
                          ? const SizedBox.shrink()
                          : Text(
                              value['text']!,
                              style: theme.textTheme.titleMedium!.copyWith(
                                fontFamily: value['fontFamily'],
                                color: value['color'],
                                fontSize: 30,
                              ),
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
          //------------------------------------------------------------
          //Font selection and TextBox
          AnimatedPadding(
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 0),
            duration: const Duration(milliseconds: 0),
            curve: Curves.linear,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ValueListenableBuilder(
                      valueListenable: _selectedFontFamily,
                      builder: (context, selectedFontFamily, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List<Widget>.generate(textStyleList.length,
                              (index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right:
                                    index != textStyleList.length - 1 ? 10 : 0,
                              ),
                              child: FontReview(
                                style: textStyleList[index],
                                isActive:
                                    selectedFontFamily == fontFamilyList[index],
                                onPressed: () {
                                  log('Selected font is: ${fontFamilyList[index]}');
                                  _selectedFontFamily.value =
                                      fontFamilyList[index];
                                  final newText = _createText(
                                      _typedText.value,
                                      _selectedFontFamily.value,
                                      _selectedColor.value);
                                  _displayedText.value = newText;
                                },
                              ),
                            );
                          }),
                        );
                      }),
                ),
                const SizedBox(
                  height: 10,
                ),
                //Text form field for typing the text
                SizedBox(
                  height: 50,
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      hintText: 'Add text',
                      hintStyle: const TextStyle(
                        color: Color(0xFF7C7C7C),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2D2D2D),
                    ),
                    onChanged: (value) {
                      _typedText.value = value;
                      final newText = _createText(_typedText.value,
                          _selectedFontFamily.value, _selectedColor.value);
                      _displayedText.value = newText;
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class FontReview extends StatelessWidget {
  const FontReview({
    super.key,
    required this.style,
    required this.onPressed,
    this.isActive = false,
  });

  final TextStyle style;
  final void Function() onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 21),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          border: isActive ? Border.all(color: Colors.white) : null,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          'Aa',
          style: style,
        ),
      ),
    );
  }
}
