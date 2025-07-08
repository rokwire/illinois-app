enum ResourceType {panel, external_link}

enum ResourceDetailType {text, address, phone, email, external_link}

class ResourceList {
  final String title;
  final List<Resource> resources;

  ResourceList({
    required this.title,
    required this.resources
});
}

class DetailListSection {
  final String? title;
  final List<ResourceDetail>? content;

  DetailListSection({
    this.title,
    this.content
  });
}

class Resource {
  final String id;
  final ResourceType type;
  final String title;
  final List<ResourceDetail> directoryContent;
  final String? description;
  final List<DetailListSection>? detailsList;

  Resource({
    required this.id,
    required this.type,
    required this.title,
    required this.directoryContent,
    this.description,
    this.detailsList
  });
}

class ResourceDetail {
  final ResourceDetailType type;
  final String? content;

  ResourceDetail({
    required this.type,
    this.content
  });
}

class ResourceListScreen {
  final String id;
  final String type;
  final String? title;
  final String? description;
  final List<ResourceList>? content;

  ResourceListScreen({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.content
  });
}
