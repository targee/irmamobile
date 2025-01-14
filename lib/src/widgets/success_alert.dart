// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/theme/theme.dart';

class SuccessAlert extends StatelessWidget {
  final String title;
  final String body;

  const SuccessAlert({Key key, @required this.title, @required this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: IrmaTheme.of(context).notificationSuccessBg,
        border: Border.all(color: const Color(0xffbbbbbb)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SvgPicture.asset(
              'assets/generic/check.svg',
              width: 24,
            ),
            SizedBox(
              width: IrmaTheme.of(context).smallSpacing,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(
                    height: IrmaTheme.of(context).smallSpacing,
                  ),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyText2.copyWith(
                          color: IrmaTheme.of(context).grayscale40,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
