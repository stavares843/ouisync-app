import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../utils/utils.dart';

class EqValues extends StatelessWidget {
  const EqValues({super.key});

  @override
  Widget build(BuildContext context) => Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
          childrenPadding: EdgeInsets.symmetric(vertical: 20.0),
          title: Text(S.current.messageTapForValues,
              textAlign: TextAlign.end,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: Dimensions.fontSmall,
                  fontStyle: FontStyle.italic)),
          children: [_valuesTextBlock(context)]));

  Widget _valuesTextBlock(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        RichText(
            textAlign: TextAlign.start,
            text: TextSpan(
                style: TextStyle(
                    color: Colors.black87, fontSize: Dimensions.fontSmall),
                children: [
                  Fields.boldTextSpan('\n${S.current.titleEqualitiesValues}\n',
                      fontSize: Dimensions.fontBig)
                ])),
        RichText(
            textAlign: TextAlign.end,
            text: Fields.quoteTextSpan(
                '${S.current.messageQuoteMainIsFree}\n\n',
                S.current.messageRousseau)),
        RichText(
          text: TextSpan(
            style: TextStyle(
                color: Colors.black87, fontSize: Dimensions.fontSmall),
            children: [
              TextSpan(text: S.current.messageEqValuesP1),
              Fields.linkTextSpan(
                  context,
                  '${S.current.messageInternationalBillHumanRights}.\n\n',
                  _launchIBoHR),
              TextSpan(text: '${S.current.messageEqValuesP2}.\n\n'),
              TextSpan(text: '${S.current.messageEqValuesP3}.\n\n'),
              Fields.boldTextSpan('${S.current.titleOurMission}\n\n'),
              TextSpan(text: '${S.current.messageEqValuesP4}.\n\n'),
              TextSpan(text: '${S.current.messageEqValuesP5}.\n\n'),
              Fields.boldTextSpan('${S.current.titleWeAreEq}\n\n'),
              TextSpan(text: '${S.current.messageEqValuesP6}.\n\n'),
              Fields.boldTextSpan('${S.current.titleOurPrinciples}\n\n'),
              TextSpan(text: '${S.current.messageEqValuesP7}.\n\n'),
              Fields.boldTextSpan('- ${S.current.titlePrivacy}\n\n'),
              TextSpan(text: S.current.messageEqValuesP8),
              Fields.linkTextSpan(context,
                  '${S.current.messageDeclarationDOS}.\n\n', _launchDfDOS),
              Fields.boldTextSpan('- ${S.current.titleDigitalSecurity}\n\n'),
              TextSpan(text: '${S.current.messageEqValuesP9}.\n\n'),
              Fields.boldTextSpan(
                  '- ${S.current.titleOpennessTransparency}\n\n'),
              TextSpan(text: '${S.current.messageEqValuesP10}\n\n'),
              Fields.boldTextSpan(
                  '- ${S.current.titleFreedomExpresionAccessInfo}\n\n'),
              TextSpan(text: '${S.current.messageEqValuesP11}.\n\n'),
              Fields.boldTextSpan('- ${S.current.titleJustLegalSociety}\n\n'),
              TextSpan(
                  text: '${S.current.messageEqValuesP12}.\n\n'
                      '${S.current.messageEqValuesP13}.\n\n'
                      '${S.current.messageEqValuesP14}.'),
            ],
          ),
        )
      ]);

  void _launchIBoHR(BuildContext context) async {
    final title = Text(S.current.messageInternationalBillHumanRights);
    await Fields.openUrl(context, title, Constants.billHumanRightsUrl);
  }

  void _launchDfDOS(BuildContext context) async {
    final title = Text(S.current.messageDeclarationDOS);
    await Fields.openUrl(context, title, Constants.eqDeclarationDOS);
  }
}
