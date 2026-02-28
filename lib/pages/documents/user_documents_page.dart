import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:inhabit_realties/controllers/document/DocumentController.dart';
import 'package:inhabit_realties/models/document/DocumentModel.dart';
import 'package:inhabit_realties/models/document/DocumentTypeModel.dart';
import 'package:inhabit_realties/pages/widgets/appSnackBar.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:inhabit_realties/pages/documents/widgets/add_new_document_button.dart';
import 'package:url_launcher/url_launcher.dart';

class UserDocumentsPage extends StatefulWidget {
  const UserDocumentsPage({Key? key}) : super(key: key);

  @override
  State<UserDocumentsPage> createState() => _UserDocumentsPageState();
}

class _UserDocumentsPageState extends State<UserDocumentsPage> {
  final DocumentController _documentController = DocumentController();
  List<DocumentModel> _documents = [];
  List<DocumentTypeModel> _documentTypes = [];
  bool _isLoading = false;
  String? _userId;
  String _searchQuery = '';

  // Map to store expanded state for each document type
  Map<String, bool> _expandedSections = {};

  List<DocumentModel> get _filteredDocuments {
    if (_searchQuery.isEmpty) {
      return _documents;
    }
    return _documents
        .where((doc) =>
            doc.fileName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // Group documents by document type
  Map<String, List<DocumentModel>> get _groupedDocuments {
    final Map<String, List<DocumentModel>> grouped = {};

    for (final doc in _filteredDocuments) {
      final documentType = _getDocumentTypeName(doc.documentTypeId);
      if (!grouped.containsKey(documentType)) {
        grouped[documentType] = [];
      }
      grouped[documentType]!.add(doc);
    }

    return grouped;
  }

  String _getDocumentTypeName(String documentTypeId) {
    try {
      final documentType =
          _documentTypes.firstWhere((type) => type.id == documentTypeId);
      return documentType.name;
    } catch (e) {
      return 'Unknown Type';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserIdAndDocuments();
  }

  Future<void> _loadUserIdAndDocuments() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('currentUser') ?? '';

    if (currentUser.isNotEmpty) {
      try {
        final userData = jsonDecode(currentUser);
        final userId = userData['_id'] ?? '';
        setState(() {
          _userId = userId;
        });
      } catch (e) {
        setState(() {
          _userId = '';
        });
      }
    } else {
      setState(() {
        _userId = '';
      });
    }

    await _loadDocuments();
    await _loadDocumentTypes();
  }

  Future<void> _loadDocumentTypes() async {
    try {
      final response = await _documentController.getAllDocumentTypes();
      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          _documentTypes = _documentController.documentTypes;
        });
      }
    } catch (error) {
      // Error handled silently
    }
  }

  Future<void> _loadDocuments() async {
    if (_userId == null || _userId!.isEmpty) {
      setState(() => _isLoading = false);
      AppSnackBar.showSnackBar(
        context,
        'Error',
        'User ID not found. Please log in again.',
        ContentType.failure,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _documentController.getAllDocuments();

      if (response['statusCode'] == 200 && mounted) {
        final userDocuments =
            _documentController.getDocumentsByUserId(_userId!);
        // Documents loaded successfully

        setState(() {
          _documents = userDocuments;
          _isLoading = false;
        });

        // Initialize expanded state for new document types
        for (final doc in userDocuments) {
          final documentType = _getDocumentTypeName(doc.documentTypeId);
          if (!_expandedSections.containsKey(documentType)) {
            _expandedSections[documentType] = true; // Default to expanded
          }
        }

        // Documents processed successfully
      } else {
        setState(() => _isLoading = false);
        // Failed to load documents
        AppSnackBar.showSnackBar(
          context,
          'Error',
          response['message'] ?? 'Failed to load documents',
          ContentType.failure,
        );
      }
    } catch (error) {
      setState(() => _isLoading = false);
      // Exception loading documents
      AppSnackBar.showSnackBar(
        context,
        'Error',
        'Exception loading documents: $error',
        ContentType.failure,
      );
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    final response = await _documentController.deleteDocument(documentId);
    if (response['statusCode'] == 200 && mounted) {
      AppSnackBar.showSnackBar(
        context,
        'Success',
        'Document deleted successfully',
        ContentType.success,
      );
      await _loadDocuments();
    } else {
      AppSnackBar.showSnackBar(
        context,
        'Error',
        response['message'] ?? 'Failed to delete document',
        ContentType.failure,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey[800] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
          ),
          // Add New Document button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _userId != null && _userId!.isNotEmpty
                ? AddNewDocumentButton(
                    userId: _userId!,
                    onDocumentAdded: _loadDocuments,
                  )
                : Container(), // Show nothing if userId is not available
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: cardColor,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Total Documents Count
          if (!_isLoading && _documents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Documents',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_filteredDocuments.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Documents List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDocuments,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _groupedDocuments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.doc_text,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No documents found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _groupedDocuments.length,
                          itemBuilder: (context, index) {
                            final documentType =
                                _groupedDocuments.keys.elementAt(index);
                            final documents = _groupedDocuments[documentType]!;
                            return _buildDocumentTypeSection(
                                documentType, documents);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeSection(
      String documentType, List<DocumentModel> documents) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey[800] : Colors.white;
    final isExpanded = _expandedSections[documentType] ?? true;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedSections[documentType] = expanded;
          });
        },
        leading: Icon(
          _getDocumentTypeIcon(documentType),
          color: _getDocumentTypeColor(documentType),
          size: 28,
        ),
        title: Text(
          documentType,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
          ),
        ),
        subtitle: Text(
          '${documents.length} document${documents.length != 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        children: documents.map((doc) => _buildDocumentCard(doc)).toList(),
      ),
    );
  }

  IconData _getDocumentTypeIcon(String documentType) {
    switch (documentType.toUpperCase()) {
      case 'IDENTITY_PROOF':
        return Icons.verified_user;
      case 'ADDRESS_PROOF':
        return Icons.home;
      case 'INCOME_PROOF':
        return Icons.attach_money;
      case 'PROPERTY_DOCUMENTS':
        return Icons.business;
      case 'AGREEMENT_DOCUMENTS':
        return Icons.description;
      default:
        return Icons.folder;
    }
  }

  Color _getDocumentTypeColor(String documentType) {
    switch (documentType.toUpperCase()) {
      case 'IDENTITY_PROOF':
        return Colors.blue;
      case 'ADDRESS_PROOF':
        return Colors.green;
      case 'INCOME_PROOF':
        return Colors.orange;
      case 'PROPERTY_DOCUMENTS':
        return Colors.purple;
      case 'AGREEMENT_DOCUMENTS':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDocumentCard(DocumentModel doc) {
    try {
      final isImage = doc.isImage;
      final isPdf = doc.isPdf;
      final isDoc = doc.isDocument;
      final icon = isImage
          ? Icons.image
          : isPdf
              ? Icons.picture_as_pdf
              : isDoc
                  ? Icons.description
                  : Icons.insert_drive_file;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(icon, size: 32),
            title: Text(doc.fileName),
            subtitle: Text(
                '${doc.fileSizeFormatted} • ${doc.mimeType ?? 'Unknown type'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.blue),
                  onPressed: () async {
                    final url = doc.displayDocumentUrl;
                    if (url.isNotEmpty) {
                      try {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } else {
                          AppSnackBar.showSnackBar(
                            context,
                            'Error',
                            'Could not download document. Please try again.',
                            ContentType.failure,
                          );
                        }
                      } catch (error) {
                        AppSnackBar.showSnackBar(
                          context,
                          'Error',
                          'Error downloading document: $error',
                          ContentType.failure,
                        );
                      }
                    } else {
                      AppSnackBar.showSnackBar(
                        context,
                        'Error',
                        'Document URL not available.',
                        ContentType.failure,
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Document'),
                        content: const Text(
                            'Are you sure you want to delete this document?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _deleteDocument(doc.id);
                    }
                  },
                ),
              ],
            ),
            onTap: () async {
              // Open the document URL in browser or viewer
              final url = doc.displayDocumentUrl;

              if (url.isNotEmpty) {
                try {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    AppSnackBar.showSnackBar(
                      context,
                      'Error',
                      'Could not open document. Please try again.',
                      ContentType.failure,
                    );
                  }
                } catch (error) {
                  AppSnackBar.showSnackBar(
                    context,
                    'Error',
                    'Error opening document: $error',
                    ContentType.failure,
                  );
                }
              } else {
                AppSnackBar.showSnackBar(
                  context,
                  'Error',
                  'Document URL not available.',
                  ContentType.failure,
                );
              }
            },
          ),
        ),
      );
    } catch (error) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.error, size: 32, color: Colors.red),
            title: const Text('Error loading document'),
            subtitle: Text('Error: $error'),
          ),
        ),
      );
    }
  }
}
