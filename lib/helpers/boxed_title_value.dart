import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class BoxedTitleAndValue extends StatelessWidget {
  const BoxedTitleAndValue({Key? key, required this.title, required this.value}) : super(key: key);
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
            decoration: ShapeDecoration(color: Theme.of(context).appBarTheme.backgroundColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
            child: Column(
              children: [
                Center(
                    child: Text(title,
                        style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).appBarTheme.foregroundColor))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
            decoration: ShapeDecoration(color: Theme.of(context).appBarTheme.foregroundColor, shape:  RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).appBarTheme.backgroundColor!), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)))),
            child: Column(
              children: [
                Center(
                    child: AutoSizeText(value, maxLines: 1,
                        style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).appBarTheme.backgroundColor))),
              ],
            ),
          ),
        ],),
    );
  }
}

