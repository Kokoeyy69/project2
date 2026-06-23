import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import '../../models/transaction_model.dart';
import '../../widgets/status_badge_widget.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final GlobalKey _receiptKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isIncome = !widget.transaction.isDebit;
    final amountColor = isIncome ? Colors.green : Colors.red;

    return Scaffold(
       appBar: AppBar(
         title: const Text('Transaction Detail'),
         centerTitle: true,
         actions: [
           IconButton(
             icon: const Icon(Icons.share),
             onPressed: () => _showShareOptions(context),
           ),
         ],
       ),
       body: SingleChildScrollView(
         padding: const EdgeInsets.all(16),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             // Receipt wrapped with RepaintBoundary
             RepaintBoundary(
               key: _receiptKey,
               child: Column(
                 children: [
                   // Amount Card
                   Card(
                     elevation: 2,
                     child: Padding(
                       padding: const EdgeInsets.all(24),
                       child: Column(
                         children: [
                           Hero(
                             tag: 'tx_icon_${widget.transaction.id}',
                             child: Icon(
                               isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                               size: 48,
                               color: amountColor,
                             ),
                           ),
                           const SizedBox(height: 16),
                           Text(
                             '${isIncome ? '+' : '-'}${widget.transaction.amountValue.abs().toStringAsFixed(2)}',
                             style: TextStyle(
                               fontSize: 32,
                               fontWeight: FontWeight.bold,
                               color: amountColor,
                             ),
                           ),
                           const SizedBox(height: 8),
                           StatusBadgeWidget(
                             status: widget.transaction.status,
                           ),
                         ],
                       ),
                     ),
                   ),
                   const SizedBox(height: 24),
                   // Transaction Details
                   _buildDetailSection(context, 'Transaction Details', [
                     _buildDetailRow('Reference ID', widget.transaction.id),
                     _buildDetailRow('Description', widget.transaction.category),
                     _buildDetailRow(
                       'Date',
                       DateFormat('MMM dd, yyyy HH:mm')
                           .format(widget.transaction.timestamp ?? DateTime.now()),
                     ),
                     _buildDetailRow('Type', isIncome ? 'Income' : 'Expense'),
                   ]),
                   const SizedBox(height: 16),
                   // Recipient Details
                   _buildDetailSection(context, 'Recipient Details', [
                     _buildDetailRow('Name', widget.transaction.recipientName),
                   ]),
                 ],
               ),
             ),
           ],
         ),
       ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Bagikan sebagai Gambar'),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Bagikan sebagai PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsText(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareAsImage() async {
    try {
      RenderRepaintBoundary boundary =
          _receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = await getTemporaryDirectory();
      File imgFile = File('${directory.path}/receipt_${widget.transaction.id}.png');
      await imgFile.writeAsBytes(byteData!.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(imgFile.path)],
        text: 'Bukti Transaksi ${widget.transaction.id}',
      );
    } catch (e) {
      debugPrint('Error sharing as image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share as image')),
        );
      }
    }
  }

  Future<void> _shareAsText(BuildContext context) async {
    try {
      final text = '''
Transaction Receipt
-------------------
Reference: ${widget.transaction.id}
Amount: ${widget.transaction.amountValue.toStringAsFixed(2)}
Date: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.transaction.timestamp ?? DateTime.now())}
Recipient: ${widget.transaction.recipientName}
Description: ${widget.transaction.category}
Status: ${widget.transaction.status}
''';
      await Share.share(text);
    } catch (e) {
      debugPrint('Error sharing transaction: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share transaction')),
        );
      }
    }
  }
}