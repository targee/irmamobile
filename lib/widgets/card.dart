import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IrmaCardState extends State<IrmaCard>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;
  bool isUnfolded = false;

  static const indent = 100.0;
  static const headerBottom = 30.0;
  static const borderRadius = Radius.circular(15.0);
  static const padding = 15.0;
  static const personalData = [
      {'key': 'Naam', 'value': 'Anouk Meijer'},
      {'key': 'Geboren', 'value': '4 juli 1990'},
      {'key': 'E-mail', 'value': 'anouk.meijer@gmail.com'},
  ];

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    animation = Tween<double>(begin: 240, end: 500).animate(controller)
      ..addListener(() {
        setState(() {
          // The state that has changed here is the animation object’s value.
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> getDataLines() {
      var textLines = <Widget>[
        Padding(
          padding: EdgeInsets.only(left: indent, bottom: headerBottom),
          child: Text(
            "Persoonsgegevens",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Divider(color: Color(0xaaffffff)),
      ];

      for (var i = 0; i < personalData.length; i++) {
        textLines.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  child: Text(personalData[i]['key'],
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      )),
                  width: indent,
                ),
                Text(
                  personalData[i]['value'],
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return textLines;
    }

    return Container(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
                padding: const EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: getDataLines(),
                )),
          ),
          Container(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Semantics(
                    button: true,
                    enabled: false,
                    label: 'Uitvouwen',
                    child: IconButton(
                      icon: SvgPicture.asset('assets/icons/arrow-down.svg'),
                      padding: EdgeInsets.only(left: padding),
                      alignment: Alignment.centerLeft,
                      onPressed: () {
                        if (isUnfolded) {
                          print('unfold');
                          controller.forward();
                        } else {
                          print('fold');
                          controller.reverse();
                        }
                        isUnfolded = !isUnfolded;
                      },
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Bijwerken',
                  child: IconButton(
                    icon: SvgPicture.asset('assets/icons/update.svg'),
                    padding: EdgeInsets.only(right: padding),
                    onPressed: () {
                      print('update');
                    },
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Verwijderen',
                  child: IconButton(
                    icon: SvgPicture.asset('assets/icons/delete.svg'),
                    padding: EdgeInsets.only(right: padding),
                    onPressed: () {
                      print('delete');
                    },
                  ),
                ),
              ],
            ),
            height: 50,
            decoration: BoxDecoration(
              color: Color(0x55ffffff),
              borderRadius: BorderRadius.only(
                bottomLeft: borderRadius,
                bottomRight: borderRadius,
              ),
            ),
          ),
        ],
      ),
      height: animation.value,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: Color(0xffec0000),
          borderRadius: BorderRadius.all(
            borderRadius,
          ),
          image: DecorationImage(
              image: AssetImage('assets/issuers/amsterdam/bg.png'),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter)),
    );
  }
}

class IrmaCard extends StatefulWidget {
  @override
  IrmaCardState createState() => IrmaCardState();
}
