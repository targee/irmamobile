import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/disclosure/issuance_screen.dart';
import 'package:irmamobile/src/screens/disclosure/session.dart';
import 'package:irmamobile/src/screens/disclosure/widgets/arrow_back_screen.dart';
import 'package:irmamobile/src/screens/disclosure/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/disclosure/disclosure_card.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_message.dart';
import 'package:irmamobile/src/widgets/irma_quote.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:url_launcher/url_launcher.dart';

class DisclosureScreen extends StatefulWidget {
  static const String routeName = "/disclosure";

  final SessionScreenArguments arguments;

  const DisclosureScreen({this.arguments}) : super();

  @override
  _DisclosureScreenState createState() => _DisclosureScreenState();
}

class _DisclosureScreenState extends State<DisclosureScreen> {
  final IrmaRepository _repo = IrmaRepository.get();
  Stream<SessionState> _sessionStateStream;

  bool _displayArrowBack = false;

  void carouselPageUpdate(int disconIndex, int conIndex) {
    _dispatchSessionEvent(
      DisclosureChoiceUpdateSessionEvent(
        disconIndex: disconIndex,
        conIndex: conIndex,
      ),
      isBridgedEvent: false,
    );
  }

  @override
  void initState() {
    super.initState();

    _sessionStateStream = _repo.getSessionState(widget.arguments.sessionID);

    _sessionStateStream
        .firstWhere((session) => session.disclosuresCandidates != null)
        .then((session) => _showExplanation(session.disclosuresCandidates));

    _sessionStateStream
        .firstWhere((session) => session.requestPin == true)
        .then((session) => pushSessionPinScreen(context, session.sessionID, 'disclosure.title'));

    // Handle errors. The return code is replicated here as we start
    // with a somewhat different situation, having an extra screen
    // on top of the stack
    _sessionStateStream.firstWhere((session) => session.status == SessionStatus.error).then((session) {
      toErrorScreen(context, session.error, () {
        (() async {
          if (session.continueOnSecondDevice) {
            popToWallet(context);
          } else if (session.clientReturnURL != null && await canLaunch(session.clientReturnURL)) {
            launch(session.clientReturnURL, forceSafariVC: false);
            popToWallet(context);
          } else {
            if (Platform.isIOS) {
              setState(() => _displayArrowBack = true);
              Navigator.of(context).pop(); // pop error screen
            } else {
              SystemNavigator.pop();
              popToWallet(context);
            }
          }
        })();
      });
    });

    // Session end handling
    (() async {
      // When the session has completed, wait one second to display a message
      final session = await _sessionStateStream.firstWhere((session) {
        switch (session.status) {
          case SessionStatus.success:
          case SessionStatus.canceled:
            return true;
          default:
            return false;
        }
      });
      if (session.issuedCredentials?.isNotEmpty ?? false) {
        // Let issuance screen handle this
        return;
      }
      await Future.delayed(const Duration(seconds: 1));

      if (session.continueOnSecondDevice) {
        // If this is a session on a second screen, return to the wallet after showing a feedback screen
        if (session.status == SessionStatus.success) {
          _pushDisclosureFeedbackScreen(
              true, session.serverName.translate(FlutterI18n.currentLocale(context).languageCode));
        } else {
          // TODO: Show an error/cancel feedback screen.
          popToWallet(context);
        }
      } else if (session.clientReturnURL != null && await canLaunch(session.clientReturnURL)) {
        // If there is a return URL, navigate to it when we're done
        launch(session.clientReturnURL, forceSafariVC: false);
        popToWallet(context);
      } else {
        // Otherwise, on iOS show a screen to press the return arrow in the top-left corner,
        // and on Android just background the app to let the user return to the previous activity
        if (Platform.isIOS) {
          setState(() => _displayArrowBack = true);
        } else {
          SystemNavigator.pop();
          popToWallet(context);
        }
      }
    })();
  }

  void _pushDisclosureFeedbackScreen(bool success, String otherParty) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DisclosureFeedbackScreen(
        success: success,
        otherParty: otherParty,
        popToWallet: popToWallet,
      ),
    ));
  }

  void _dispatchSessionEvent(SessionEvent event, {bool isBridgedEvent = true}) {
    event.sessionID = widget.arguments.sessionID;
    _repo.dispatch(event, isBridgedEvent: isBridgedEvent);
  }

  void _dismissSession() {
    _dispatchSessionEvent(RespondPermissionEvent(
      proceed: false,
      disclosureChoices: [],
    ));
  }

  void _declinePermission(BuildContext context, String otherParty) {
    _dismissSession();
    _pushDisclosureFeedbackScreen(false, otherParty);
  }

  void _givePermission(SessionState session) {
    if (session.issuedCredentials?.isNotEmpty ?? false) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        IssuanceScreen.routeName,
        ModalRoute.withName(WalletScreen.routeName),
        arguments: widget.arguments,
      );
    } else {
      _dispatchSessionEvent(RespondPermissionEvent(
        proceed: true,
        disclosureChoices: session.disclosureChoices,
      ));
    }
  }

  Widget _buildDisclosureHeader(SessionState session) {
    return StreamBuilder<SessionState>(
        stream: _sessionStateStream,
        builder: (context, sessionStateSnapshot) {
          if (!sessionStateSnapshot.hasData || sessionStateSnapshot.data.status != SessionStatus.requestPermission) {
            return Container(height: 0);
          }

          final state = sessionStateSnapshot.data;
          if (!state.satisfiable) {
            return Column(
              children: <Widget>[
                const IrmaMessage(
                  'disclosure.unsatisfiable_title',
                  'disclosure.unsatisfiable_message',
                  type: IrmaMessageType.info,
                ),
                SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                TranslatedText(
                  'disclosure.unsatisfiable_request',
                  translationParams: {
                    "otherParty": session.serverName.translate(FlutterI18n.currentLocale(context).languageCode)
                  },
                  style: Theme.of(context).textTheme.body1,
                ),
              ],
            );
          } else {
            return Column(
              children: <Widget>[
                TranslatedText(
                  'disclosure.disclosure_header',
                  translationParams: {
                    "otherParty": session.serverName.translate(FlutterI18n.currentLocale(context).languageCode)
                  },
                  style: Theme.of(context).textTheme.body1,
                ),
              ],
            );
          }
        });
  }

  Widget _buildSigningHeader(SessionState session) {
    return Column(children: [
      Text.rich(
        TextSpan(children: [
          TextSpan(
            text: session.serverName.translate(FlutterI18n.currentLocale(context).languageCode),
            style: IrmaTheme.of(context).textTheme.body2,
          ),
          TextSpan(
            text: FlutterI18n.translate(context, 'disclosure.signing_header'),
            style: IrmaTheme.of(context).textTheme.body1,
          ),
        ]),
      ),
      Padding(
        padding: EdgeInsets.only(top: IrmaTheme.of(context).mediumSpacing),
        child: IrmaQuote(quote: session.signedMessage),
      ),
    ]);
  }

  Widget _buildNavigationBar() {
    return StreamBuilder<SessionState>(
      stream: _sessionStateStream,
      builder: (context, sessionStateSnapshot) {
        if (!sessionStateSnapshot.hasData || sessionStateSnapshot.data.status != SessionStatus.requestPermission) {
          return Container(height: 0);
        }

        final state = sessionStateSnapshot.data;
        return state.satisfiable
            ? IrmaBottomBar(
                primaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.yes"),
                onPrimaryPressed: state.canDisclose ? () => _givePermission(state) : null,
                secondaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.no"),
                onSecondaryPressed: () => _declinePermission(
                    context, state.serverName.translate(FlutterI18n.currentLocale(context).languageCode)),
              )
            : IrmaBottomBar(
                primaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.back"),
                onPrimaryPressed: () => _declinePermission(
                    context, state.serverName.translate(FlutterI18n.currentLocale(context).languageCode)),
              );
      },
    );
  }

  Widget _buildDisclosureChoices(SessionState session) {
    // TODO: See how disclosure_card.dart fits in here
    return ListView(
      padding: EdgeInsets.all(IrmaTheme.of(context).smallSpacing),
      children: <Widget>[
        Padding(
            padding: EdgeInsets.symmetric(
              vertical: IrmaTheme.of(context).mediumSpacing,
              horizontal: IrmaTheme.of(context).smallSpacing,
            ),
            child: session.isSignatureSession ? _buildSigningHeader(session) : _buildDisclosureHeader(session)),
        DisclosureCard(
          candidatesConDisCon: session.disclosuresCandidates,
          onCurrentPageUpdate: carouselPageUpdate,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_displayArrowBack) {
      return ArrowBack();
    }

    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(FlutterI18n.translate(context, 'disclosure.title')),
        leadingCancel: () => _dismissSession(),
      ),
      backgroundColor: IrmaTheme.of(context).grayscaleWhite,
      bottomNavigationBar: _buildNavigationBar(),
      body: StreamBuilder(
        stream: _sessionStateStream,
        builder: (BuildContext context, AsyncSnapshot<SessionState> sessionStateSnapshot) {
          if (!sessionStateSnapshot.hasData) {
            return buildLoadingIndicator();
          }

          final session = sessionStateSnapshot.data;
          if (session.status == SessionStatus.requestPermission) {
            return _buildDisclosureChoices(session);
          }

          return buildLoadingIndicator();
        },
      ),
    );
  }

  Future<void> _showExplanation(ConDisCon<Attribute> candidatesConDisCon) async {
    final irmaPrefs = IrmaPreferences.get();

    final bool showDisclosureDialog = await irmaPrefs.getShowDisclosureDialog().first;
    final hasChoice = candidatesConDisCon.any((candidatesDisCon) => candidatesDisCon.length > 1);

    if (!showDisclosureDialog || !hasChoice) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => IrmaDialog(
        title: FlutterI18n.translate(context, 'disclosure.explanation.title'),
        content: FlutterI18n.translate(context, 'disclosure.explanation.body'),
        image: 'assets/disclosure/disclosure-explanation.webp',
        child: Wrap(
          direction: Axis.horizontal,
          verticalDirection: VerticalDirection.up,
          alignment: WrapAlignment.spaceEvenly,
          children: <Widget>[
            IrmaTextButton(
              onPressed: () async {
                await irmaPrefs.setShowDisclosureDialog(false);
                Navigator.of(context).pop();
              },
              minWidth: 0.0,
              label: 'disclosure.explanation.dismiss-remember',
            ),
            IrmaButton(
              size: IrmaButtonSize.small,
              minWidth: 0.0,
              onPressed: () {
                Navigator.of(context).pop();
              },
              label: 'disclosure.explanation.dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
