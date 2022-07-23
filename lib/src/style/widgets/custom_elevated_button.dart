import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../audio/sounds.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final void Function() action;
  const CustomElevatedButton({
    Key? key,
    required this.text,
    required this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioController = context.watch<AudioController>();
    return ElevatedButton(
      onPressed: () {
        audioController.playSfx(SfxType.buttonTap);
        action();
      },
      child: Text(text),
    );
  }
}

class CustomElevatedButtonGo extends StatelessWidget {
  final String text;
  final String path;
  const CustomElevatedButtonGo({
    Key? key,
    required this.text,
    required this.path,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomElevatedButton(
      action: () => GoRouter.of(context).go(path),
      text: text,
    );
  }
}

class CustomElevatedButtonBack extends StatelessWidget {
  final String text;
  const CustomElevatedButtonBack({Key? key, this.text = 'Back'})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomElevatedButton(
      action: () => GoRouter.of(context).pop(),
      text: text,
    );
  }
}
