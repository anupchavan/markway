import CoreData
import Foundation
import Darwin
import AVFoundation

#if targetEnvironment(macCatalyst)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
typealias PlatformImage = UIImage
#else
import AppKit
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
typealias PlatformImage = NSImage
#endif

struct MergeableEntryAttributesOpaque {
    var w0: UInt64 = 0
    var w1: UInt64 = 0
    var w2: UInt64 = 0
    var w3: UInt64 = 0
    var w4: UInt64 = 0
    var w5: UInt64 = 0
    var w6: UInt64 = 0
    var w7: UInt64 = 0
    var w8: UInt64 = 0
    var w9: UInt64 = 0
    var w10: UInt64 = 0
    var w11: UInt64 = 0
}

struct ProviderWitnessPair {
    var metadata: UnsafeRawPointer?
    var witness: UnsafeRawPointer?
}

struct ProviderExistential {
    var value0: UnsafeRawPointer?
    var value1: UnsafeRawPointer?
    var value2: UnsafeRawPointer?
    var metadata: UnsafeRawPointer?
    var witness: UnsafeRawPointer?
}

@_silgen_name("$s13JournalShared24MergeableEntryAttributesV12defaultStateACyt_tKcfC")
func jsMergeableEntryAttributesDefaultState(_ typeMetadata: UnsafeRawPointer) throws -> MergeableEntryAttributesOpaque

@_silgen_name("$s13JournalShared24MergeableEntryAttributesVMa")
func jsMergeableEntryAttributesMetadata(_ request: UInt64) -> UnsafeRawPointer

@_silgen_name("$s13JournalShared31WrappedMergeableEntryAttributesCMa")
func jsWrappedMergeableEntryAttributesMetadata(_ request: UInt64) -> UnsafeRawPointer

@_silgen_name("js_call_wrap_mergeable_entry_attributes")
func jsShimWrapMergeableEntryAttributes(_ valueAddress: UnsafeMutableRawPointer, _ wrapperMetadata: UnsafeRawPointer) -> NSObject

@_silgen_name("js_call_cr_attributed_string_text_metadata")
func jsShimCRTextMetadata() -> UnsafeRawPointer

@_silgen_name("js_call_cr_attributed_string_title_metadata")
func jsShimCRTitleMetadata() -> UnsafeRawPointer

@_silgen_name("js_call_cr_attributed_string_text_attributes_metadata")
func jsShimCRTextAttributesMetadata() -> UnsafeRawPointer

@_silgen_name("js_call_cr_attributed_string_title_attributes_metadata")
func jsShimCRTitleAttributesMetadata() -> UnsafeRawPointer

@_silgen_name("js_call_cr_attributed_string_from_ns_text")
func jsShimCRFromNSText(_ attributed: NSAttributedString, _ valueAddress: UnsafeMutableRawPointer)

@_silgen_name("js_call_cr_attributed_string_from_ns_title")
func jsShimCRFromNSTitle(_ attributed: NSAttributedString, _ valueAddress: UnsafeMutableRawPointer)

@_silgen_name("js_call_mergeable_entry_merge_text")
func jsShimMergeText(_ crAddress: UnsafeMutableRawPointer, _ entryAddress: UnsafeMutableRawPointer)

@_silgen_name("js_call_mergeable_entry_merge_title")
func jsShimMergeTitle(_ crAddress: UnsafeMutableRawPointer, _ entryAddress: UnsafeMutableRawPointer)

@_silgen_name("js_call_cr_attributed_string_add_attrs_text")
func jsShimCRAddAttrsText(_ crAddress: UnsafeMutableRawPointer, _ attrsAddress: UnsafeMutableRawPointer, _ location: Int, _ length: Int)

@_silgen_name("js_call_cr_attributed_string_add_attrs_title")
func jsShimCRAddAttrsTitle(_ crAddress: UnsafeMutableRawPointer, _ attrsAddress: UnsafeMutableRawPointer, _ location: Int, _ length: Int)

@_silgen_name("js_call_destroy_swift_value")
func jsShimDestroySwiftValue(_ valueAddress: UnsafeMutableRawPointer, _ metadata: UnsafeRawPointer)

@_silgen_name("js_call_cr_attributed_string_to_ns_text")
func jsShimCRToNSText(_ valueAddress: UnsafeMutableRawPointer) -> NSAttributedString

@_silgen_name("js_call_cr_attributed_string_count")
func jsShimCRAttributedStringCount(_ valueAddress: UnsafeMutableRawPointer) -> Int

@_silgen_name("js_call_cr_attributed_string_remove_range")
func jsShimCRAttributedStringRemoveRange(_ valueAddress: UnsafeMutableRawPointer, _ lowerBound: Int, _ upperBound: Int)

@_silgen_name("js_call_cr_attributed_string_insert_ns")
func jsShimCRAttributedStringInsertNS(_ valueAddress: UnsafeMutableRawPointer, _ attributed: NSAttributedString, _ index: Int)

@_silgen_name("js_call_wrapped_mergeable_entry_attributes_value")
func jsShimWrappedMergeableEntryAttributesValue(_ wrapper: NSObject, _ valueAddress: UnsafeMutableRawPointer)

@_silgen_name("js_call_mergeable_entry_title_getter")
func jsShimMergeableEntryTitleGetter(_ entryAddress: UnsafeMutableRawPointer, _ valueAddress: UnsafeMutableRawPointer)

@_silgen_name("js_call_mergeable_entry_text_getter")
func jsShimMergeableEntryTextGetter(_ entryAddress: UnsafeMutableRawPointer, _ valueAddress: UnsafeMutableRawPointer)

@_silgen_name("js_call_mergeable_entry_asset_placement_getter")
func jsShimMergeableEntryAssetPlacementGetter(_ entryAddress: UnsafeMutableRawPointer, _ valueAddress: UnsafeMutableRawPointer)

@_silgen_name("js_call_mergeable_entry_assets_placement_metadata")
func jsShimMergeableEntryAssetsPlacementMetadata() -> UnsafeRawPointer

@_silgen_name("js_call_mergeable_entry_assets_placement_from_legacy")
func jsShimMergeableEntryAssetsPlacementFromLegacy(_ entry: NSManagedObject, _ valueAddress: UnsafeMutableRawPointer)

@_silgen_name("js_call_mergeable_entry_merge_asset_placement")
func jsShimMergeAssetPlacement(_ placementAddress: UnsafeMutableRawPointer, _ entryAddress: UnsafeMutableRawPointer)

@_silgen_name("js_call_swift_fn0_return_pair")
func jsShimSwiftFn0ReturnPair(_ function: UnsafeRawPointer, _ outPair: UnsafeMutablePointer<ProviderWitnessPair>)

@_silgen_name("js_call_swift_provider_init_to_buffer")
func jsShimSwiftProviderInitToBuffer(
    _ function: UnsafeRawPointer,
    _ metadata: UnsafeRawPointer,
    _ witness: UnsafeRawPointer,
    _ resultAddress: UnsafeMutableRawPointer
)

#if targetEnvironment(macCatalyst)
@_silgen_name("js_call_journalui_cr_attributes")
func jsShimJournalUICRAttributes(
    _ function: UnsafeRawPointer,
    _ resultAddress: UnsafeMutableRawPointer,
    _ attributes: [NSAttributedString.Key: Any],
    _ traitCollection: UITraitCollection,
    _ providerExistential: UnsafeRawPointer
)
#endif

let defaultStorePath = "\(NSHomeDirectory())/Library/Group Containers/group.com.apple.moments/Library/moments.sqlite"
let defaultAttachmentRootPath = "\(NSHomeDirectory())/Library/Group Containers/group.com.apple.moments/Library/Attachments"
let modelPath = "/System/Library/PrivateFrameworks/JournalShared.framework/Versions/A/Resources/moments.momd"

struct Options {
    var storePath = defaultStorePath
    var attachmentRootPath = defaultAttachmentRootPath
    var readOnly = false
    var command: String = ""
    var operands: [String] = []
    var title: String?
    var bodyPath: String?
    var outputPath: String?
    var hardDelete = false
    var keepFiles = false
    var json = false
}

enum ToolError: Error, CustomStringConvertible {
    case usage(String)
    case notFound(String)
    case invalid(String)

    var description: String {
        switch self {
        case .usage(let message), .notFound(let message), .invalid(let message):
            return message
        }
    }
}

func usage() -> String {
    """
    usage:
      journal_text list [--store PATH]
      journal_text get UUID [--store PATH]
      journal_text add --title TITLE --body BODY.md [--store PATH]
      journal_text update UUID [--title TITLE] [--body BODY.md] [--store PATH]
      journal_text delete UUID [--hard] [--store PATH]
      journal_text purge UUID [--store PATH]
      journal_text sync-status [UUID] [--store PATH]
      journal_text queue-upload UUID [--store PATH]
      journal_text debug-attrs UUID [--store PATH]
      journal_text debug-markdown --body BODY.md
      journal_text attachments types [--store PATH]
      journal_text attachments list UUID [--store PATH] [--attachment-root PATH] [--json]
      journal_text attachments export UUID --out DIR [--store PATH] [--attachment-root PATH]
      journal_text attachments reorder UUID ASSET_UUID... [--store PATH]
      journal_text attachments resize UUID ASSET_UUID grid|slim [--store PATH]
      journal_text attachments delete UUID ASSET_UUID [--store PATH] [--attachment-root PATH] [--keep-files]
      journal_text attachments normalize-metadata UUID [ASSET_UUID...] [--store PATH]
      journal_text attachments add-photo UUID IMAGE_PATH [grid|slim] [--store PATH] [--attachment-root PATH]
      journal_text attachments add-video UUID VIDEO.mov [grid|slim] [--store PATH] [--attachment-root PATH]
      journal_text attachments add-live-photo UUID IMAGE_PATH VIDEO.mov [grid|slim] [--store PATH] [--attachment-root PATH]
      journal_text attachments add-music UUID --song SONG --artist ARTIST --media-id ID --cover IMAGE_PATH [grid|slim] [--store PATH] [--attachment-root PATH]

    BODY.md is parsed as Markdown for rich Journal text.
    delete marks an entry recentlyDeleted; purge physically deletes it with Core Data.
    """
}

func parseOptions() throws -> Options {
    var options = Options()
    var args = Array(CommandLine.arguments.dropFirst())
    var positional: [String] = []
    while !args.isEmpty {
        let arg = args.removeFirst()
        switch arg {
        case "--store":
            guard let value = args.first else { throw ToolError.usage("--store requires a path") }
            options.storePath = value
            args.removeFirst()
        case "--attachment-root":
            guard let value = args.first else { throw ToolError.usage("--attachment-root requires a path") }
            options.attachmentRootPath = value
            args.removeFirst()
        case "--title":
            guard let value = args.first else { throw ToolError.usage("--title requires a value") }
            options.title = value
            args.removeFirst()
        case "--body":
            guard let value = args.first else { throw ToolError.usage("--body requires a markdown file path") }
            options.bodyPath = value
            args.removeFirst()
        case "--out":
            guard let value = args.first else { throw ToolError.usage("--out requires a directory path") }
            options.outputPath = value
            args.removeFirst()
        case "--hard":
            options.hardDelete = true
        case "--keep-files":
            options.keepFiles = true
        case "--json":
            options.json = true
        case "-h", "--help":
            throw ToolError.usage(usage())
        default:
            positional.append(arg)
        }
    }

    guard let command = positional.first else { throw ToolError.usage(usage()) }
    options.command = command
    options.operands = Array(positional.dropFirst())
    return options
}

func loadPrivateFramework(_ path: String) throws {
    guard let bundle = Bundle(path: path) else {
        throw ToolError.invalid("missing framework: \(path)")
    }
    try bundle.loadAndReturnError()
}

func registerTransformer(_ className: String, as name: String) throws {
    guard let transformerType = NSClassFromString("JournalShared.\(className)") as? ValueTransformer.Type
            ?? NSClassFromString(className) as? ValueTransformer.Type else {
        throw ToolError.invalid("missing transformer class: \(className)")
    }
    ValueTransformer.setValueTransformer(transformerType.init(), forName: NSValueTransformerName(name))
}

func bootstrapJournalShared() throws {
    try loadPrivateFramework("/System/Library/PrivateFrameworks/Coherence.framework")
    try loadPrivateFramework("/System/Library/PrivateFrameworks/JournalShared.framework")
    try registerTransformer("MergeableEntryAttributesTransformer", as: "MergeableEntryAttributesTransformer")
    try registerTransformer("MergeableJournalAttributesTransformer", as: "MergeableJournalAttributesTransformer")
    try registerTransformer("MergeableAppStorageTransformer", as: "MergeableAppStorageTransformer")
    #if targetEnvironment(macCatalyst)
    try bootstrapJournalRichTextConverter()
    #endif
}

func makeContext(storePath: String, readOnly: Bool) throws -> NSManagedObjectContext {
    guard let model = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: modelPath)) else {
        throw ToolError.invalid("failed to load model at \(modelPath)")
    }
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    var options: [AnyHashable: Any] = [
        NSInferMappingModelAutomaticallyOption: true,
        NSMigratePersistentStoresAutomaticallyOption: true,
        NSPersistentHistoryTrackingKey: true,
        NSPersistentStoreRemoteChangeNotificationPostOptionKey: true,
    ]
    if readOnly {
        options[NSReadOnlyPersistentStoreOption] = true
    }
    try coordinator.addPersistentStore(
        ofType: NSSQLiteStoreType,
        configurationName: nil,
        at: URL(fileURLWithPath: storePath),
        options: options
    )
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    return context
}

func rtfData(_ attributed: NSAttributedString) throws -> Data {
    return try attributed.data(
        from: NSRange(location: 0, length: attributed.length),
        documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
    )
}

func rtfAttributedString(_ data: Data?) -> NSAttributedString {
    guard let data else { return NSAttributedString(string: "") }
    if let attributed = try? NSAttributedString(
        data: data,
        options: [.documentType: NSAttributedString.DocumentType.rtf],
        documentAttributes: nil
    ) {
        return attributed
    }
    return NSAttributedString(string: "")
}

func rtfString(_ data: Data?) -> String {
    rtfAttributedString(data).string
}

func plainAttributed(_ string: String) -> NSAttributedString {
    NSAttributedString(string: string, attributes: [.font: PlatformFont.systemFont(ofSize: 15)])
}

struct SwiftValueLayout {
    let size: Int
    let stride: Int
    let alignment: Int
}

func swiftValueLayout(metadata: UnsafeRawPointer) -> SwiftValueLayout {
    let pointerSize = MemoryLayout<UnsafeRawPointer>.size
    let witnessTable = metadata.load(fromByteOffset: -pointerSize, as: UnsafeRawPointer.self)
    let size = witnessTable.load(fromByteOffset: pointerSize * 8, as: Int.self)
    let stride = witnessTable.load(fromByteOffset: pointerSize * 9, as: Int.self)
    let flags = witnessTable.load(fromByteOffset: pointerSize * 10, as: UInt32.self)
    let alignment = Int(flags & 0xffff) + 1
    return SwiftValueLayout(size: size, stride: stride, alignment: alignment)
}

final class SwiftValueBuffer {
    let metadata: UnsafeRawPointer
    let pointer: UnsafeMutableRawPointer
    private var initialized = false

    init(metadata: UnsafeRawPointer) {
        self.metadata = metadata
        let layout = swiftValueLayout(metadata: metadata)
        let byteCount = max(layout.size, layout.stride)
        pointer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: layout.alignment)
        pointer.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)
    }

    func markInitialized() {
        initialized = true
    }

    func destroy() {
        if initialized {
            jsShimDestroySwiftValue(pointer, metadata)
            initialized = false
        }
    }

    deinit {
        destroy()
        pointer.deallocate()
    }
}

#if targetEnvironment(macCatalyst)
final class JournalRichTextConverter {
    private let crAttributesFunction: UnsafeRawPointer
    private let providerValue: SwiftValueBuffer
    private var providerExistential: ProviderExistential
    private let textAttributesMetadata = jsShimCRTextAttributesMetadata()

    init(bundlePath: String) throws {
        guard let bundleHandle = dlopen(bundlePath, RTLD_NOW | RTLD_GLOBAL) else {
            throw ToolError.invalid("failed to load Journal converter bundle: \(String(cString: dlerror()))")
        }
        guard let journalUIHandle = dlopen("/System/iOSSupport/System/Library/PrivateFrameworks/JournalUI.framework/JournalUI", RTLD_NOW | RTLD_GLOBAL) else {
            throw ToolError.invalid("failed to load JournalUI: \(String(cString: dlerror()))")
        }

        let preferredSymbol = "$s13JournalShared27MergeableTextAttributeScopeV0A2UI0E9Converter0A14ShareExtensionAdEP09preferredE8ProviderAD06CustomeL0_pXpvgZTW"
        let crAttributesSymbol = "$s13JournalShared27MergeableTextAttributeScopeV0A2UI0E9Converter0A14ShareExtensionAdEP12crAttributes4from15traitCollection06customE8Provider9Coherence18CRAttributedStringV0L0Vyx_GSDySo012NSAttributedT3KeyaypG_So07UITraitO0CAD06CustomeQ0_ptFZTW"
        let providerInitSymbol = "$s9JournalUI23CustomAttributeProviderPxycfCTj"

        guard let preferred = dlsym(bundleHandle, preferredSymbol),
              let crAttributes = dlsym(bundleHandle, crAttributesSymbol),
              let providerInit = dlsym(journalUIHandle, providerInitSymbol) else {
            throw ToolError.invalid("failed to resolve Journal rich-text converter symbols")
        }

        var pair = ProviderWitnessPair()
        jsShimSwiftFn0ReturnPair(preferred, &pair)
        guard let providerMetadata = pair.metadata, let providerWitness = pair.witness else {
            throw ToolError.invalid("failed to resolve Journal rich-text provider metadata")
        }

        providerValue = SwiftValueBuffer(metadata: providerMetadata)
        jsShimSwiftProviderInitToBuffer(providerInit, providerMetadata, providerWitness, providerValue.pointer)
        providerValue.markInitialized()
        let words = providerValue.pointer.assumingMemoryBound(to: Optional<UnsafeRawPointer>.self)
        providerExistential = ProviderExistential(
            value0: words[0],
            value1: words[1],
            value2: words[2],
            metadata: providerMetadata,
            witness: providerWitness
        )
        crAttributesFunction = UnsafeRawPointer(crAttributes)
    }

    func applyTextAttributes(from attributed: NSAttributedString, to crText: UnsafeMutableRawPointer) {
        guard attributed.length > 0 else { return }
        attributed.enumerateAttributes(in: NSRange(location: 0, length: attributed.length)) { attrs, range, _ in
            guard !attrs.isEmpty else { return }
            let converted = SwiftValueBuffer(metadata: textAttributesMetadata)
            withUnsafePointer(to: &providerExistential) { providerPointer in
                jsShimJournalUICRAttributes(
                    crAttributesFunction,
                    converted.pointer,
                    attrs,
                    UITraitCollection.current,
                    UnsafeRawPointer(providerPointer)
                )
            }
            converted.markInitialized()
            jsShimCRAddAttrsText(crText, converted.pointer, range.location, range.length)
            converted.destroy()
        }
    }
}

var richTextConverter: JournalRichTextConverter?

func bootstrapJournalRichTextConverter() throws {
    let executableDirectory = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path
    let bundlePath = "\(executableDirectory)/JournalShareExtension_as_bundle"
    richTextConverter = try JournalRichTextConverter(bundlePath: bundlePath)
}
#endif

func preservedAssetPlacement(from wrapper: NSObject?) -> SwiftValueBuffer? {
    guard let wrapper else { return nil }
    var oldValue = MergeableEntryAttributesOpaque()
    let placement = SwiftValueBuffer(metadata: jsShimMergeableEntryAssetsPlacementMetadata())
    withUnsafeMutableBytes(of: &oldValue) { raw in
        jsShimWrappedMergeableEntryAttributesValue(wrapper, raw.baseAddress!)
        jsShimMergeableEntryAssetPlacementGetter(raw.baseAddress!, placement.pointer)
    }
    placement.markInitialized()
    return placement
}

func makeMergeableAttributes(title: NSAttributedString, text: NSAttributedString, preservingAssetPlacementFrom wrapper: NSObject? = nil) throws -> NSObject {
    let metadata = jsMergeableEntryAttributesMetadata(0)
    var value = try jsMergeableEntryAttributesDefaultState(metadata)
    let crTitle = SwiftValueBuffer(metadata: jsShimCRTitleMetadata())
    let crText = SwiftValueBuffer(metadata: jsShimCRTextMetadata())
    let assetPlacement = preservedAssetPlacement(from: wrapper)

    jsShimCRFromNSTitle(title, crTitle.pointer)
    crTitle.markInitialized()
    jsShimCRFromNSText(text, crText.pointer)
    crText.markInitialized()
    #if targetEnvironment(macCatalyst)
    richTextConverter?.applyTextAttributes(from: text, to: crText.pointer)
    #endif

    withUnsafeMutableBytes(of: &value) { raw in
        jsShimMergeTitle(crTitle.pointer, raw.baseAddress!)
        jsShimMergeText(crText.pointer, raw.baseAddress!)
        if let assetPlacement {
            jsShimMergeAssetPlacement(assetPlacement.pointer, raw.baseAddress!)
        }
    }
    crTitle.destroy()
    crText.destroy()
    assetPlacement?.destroy()

    let wrapperMetadata = jsWrappedMergeableEntryAttributesMetadata(0)
    return withUnsafeMutableBytes(of: &value) { raw in
        jsShimWrapMergeableEntryAttributes(raw.baseAddress!, wrapperMetadata)
    }
}

func makeReplacingMergeableAttributes(title: NSAttributedString, text: NSAttributedString, from wrapper: NSObject?) throws -> NSObject {
    guard let wrapper else {
        return try makeMergeableAttributes(title: title, text: text)
    }

    var value = MergeableEntryAttributesOpaque()
    let crTitle = SwiftValueBuffer(metadata: jsShimCRTitleMetadata())
    let crText = SwiftValueBuffer(metadata: jsShimCRTextMetadata())

    withUnsafeMutableBytes(of: &value) { raw in
        jsShimWrappedMergeableEntryAttributesValue(wrapper, raw.baseAddress!)
        jsShimMergeableEntryTitleGetter(raw.baseAddress!, crTitle.pointer)
        jsShimMergeableEntryTextGetter(raw.baseAddress!, crText.pointer)
    }
    crTitle.markInitialized()
    crText.markInitialized()

    replaceCRAttributedString(crTitle, with: title)
    replaceCRAttributedString(crText, with: text)
    #if targetEnvironment(macCatalyst)
    richTextConverter?.applyTextAttributes(from: text, to: crText.pointer)
    #endif

    withUnsafeMutableBytes(of: &value) { raw in
        jsShimMergeTitle(crTitle.pointer, raw.baseAddress!)
        jsShimMergeText(crText.pointer, raw.baseAddress!)
    }

    crTitle.destroy()
    crText.destroy()

    let wrapperMetadata = jsWrappedMergeableEntryAttributesMetadata(0)
    return withUnsafeMutableBytes(of: &value) { raw in
        jsShimWrapMergeableEntryAttributes(raw.baseAddress!, wrapperMetadata)
    }
}

func replaceCRAttributedString(_ crAttributedString: SwiftValueBuffer, with attributed: NSAttributedString) {
    let count = jsShimCRAttributedStringCount(crAttributedString.pointer)
    if count > 0 {
        jsShimCRAttributedStringRemoveRange(crAttributedString.pointer, 0, count)
    }
    if attributed.length > 0 {
        jsShimCRAttributedStringInsertNS(crAttributedString.pointer, attributed, 0)
    }
}

func attributes(font: PlatformFont, extra: [NSAttributedString.Key: Any] = [:]) -> [NSAttributedString.Key: Any] {
    var result: [NSAttributedString.Key: Any] = [.font: font]
    for (key, value) in extra {
        result[key] = value
    }
    return result
}

func convertedFont(baseSize: CGFloat, bold: Bool, italic: Bool, monospace: Bool = false) -> PlatformFont {
    #if targetEnvironment(macCatalyst)
    let baseFont = monospace
        ? PlatformFont.monospacedSystemFont(ofSize: baseSize, weight: bold ? .semibold : .regular)
        : PlatformFont.systemFont(ofSize: baseSize, weight: bold ? .semibold : .regular)
    guard italic else { return baseFont }
    var traits = baseFont.fontDescriptor.symbolicTraits
    traits.insert(.traitItalic)
    guard let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits) else { return baseFont }
    return PlatformFont(descriptor: descriptor, size: baseSize)
    #else
    if monospace {
        return PlatformFont.monospacedSystemFont(ofSize: baseSize, weight: bold ? .semibold : .regular)
    }
    var font = PlatformFont.systemFont(ofSize: baseSize, weight: bold ? .semibold : .regular)
    if italic {
        font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
    }
    return font
    #endif
}

func inlineCodeBackgroundColor() -> PlatformColor {
    #if targetEnvironment(macCatalyst)
    return PlatformColor.secondarySystemBackground.withAlphaComponent(0.7)
    #else
    return PlatformColor.textBackgroundColor.withAlphaComponent(0.7)
    #endif
}

func markdownLinkColor() -> PlatformColor {
    #if targetEnvironment(macCatalyst)
    return PlatformColor.link
    #else
    return PlatformColor.linkColor
    #endif
}

func blockQuoteColor() -> PlatformColor {
    #if targetEnvironment(macCatalyst)
    return PlatformColor.secondaryLabel
    #else
    return PlatformColor.secondaryLabelColor
    #endif
}

func paragraphStyle(indent: CGFloat = 0, textLists: [NSTextList] = []) -> NSParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.paragraphSpacing = 6
    style.lineSpacing = 1.5
    style.firstLineHeadIndent = indent
    style.headIndent = indent
    style.textLists = textLists
    return style
}

struct InlineStyle {
    var bold = false
    var italic = false
    var code = false
    var link: URL?
}

func inlineAttributes(style: InlineStyle, baseSize: CGFloat, extra: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
    var attrs = attributes(
        font: convertedFont(baseSize: baseSize, bold: style.bold, italic: style.italic, monospace: style.code),
        extra: extra
    )
    if style.code {
        attrs[.backgroundColor] = inlineCodeBackgroundColor()
    }
    if let link = style.link {
        attrs[.link] = link
        attrs[.foregroundColor] = markdownLinkColor()
        attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
    }
    return attrs
}

func parseInlineMarkdown(_ markdown: String, baseSize: CGFloat, extra: [NSAttributedString.Key: Any]) -> NSAttributedString {
    let output = NSMutableAttributedString(string: "")
    let chars = Array(markdown)
    var index = 0

    func hasPrefix(_ token: String, at position: Int) -> Bool {
        let tokenChars = Array(token)
        guard position + tokenChars.count <= chars.count else { return false }
        return Array(chars[position..<position + tokenChars.count]) == tokenChars
    }

    func find(_ token: String, from position: Int) -> Int? {
        var current = position
        while current < chars.count {
            if hasPrefix(token, at: current) { return current }
            current += 1
        }
        return nil
    }

    func append(_ text: String, style: InlineStyle) {
        output.append(NSAttributedString(string: text, attributes: inlineAttributes(style: style, baseSize: baseSize, extra: extra)))
    }

    while index < chars.count {
        if hasPrefix("[", at: index), let closeBracket = find("]", from: index + 1),
           closeBracket + 1 < chars.count, chars[closeBracket + 1] == "(",
           let closeParen = find(")", from: closeBracket + 2) {
            let label = String(chars[(index + 1)..<closeBracket])
            let urlText = String(chars[(closeBracket + 2)..<closeParen])
            if let url = URL(string: urlText), url.scheme != nil {
                append(label, style: InlineStyle(link: url))
                index = closeParen + 1
                continue
            }
        }

        if hasPrefix("`", at: index), let end = find("`", from: index + 1) {
            append(String(chars[(index + 1)..<end]), style: InlineStyle(code: true))
            index = end + 1
            continue
        }

        if hasPrefix("***", at: index), let end = find("***", from: index + 3) {
            append(String(chars[(index + 3)..<end]), style: InlineStyle(bold: true, italic: true))
            index = end + 3
            continue
        }

        if hasPrefix("**", at: index), let end = find("**", from: index + 2) {
            append(String(chars[(index + 2)..<end]), style: InlineStyle(bold: true))
            index = end + 2
            continue
        }

        if hasPrefix("*", at: index), let end = find("*", from: index + 1) {
            append(String(chars[(index + 1)..<end]), style: InlineStyle(italic: true))
            index = end + 1
            continue
        }

        var next = index + 1
        while next < chars.count,
              !hasPrefix("[", at: next),
              !hasPrefix("`", at: next),
              !hasPrefix("***", at: next),
              !hasPrefix("**", at: next),
              !hasPrefix("*", at: next) {
            next += 1
        }
        append(String(chars[index..<next]), style: InlineStyle())
        index = next
    }

    return output
}

func appendMarkdownLine(_ line: String, to output: NSMutableAttributedString, baseSize: CGFloat, extra: [NSAttributedString.Key: Any]) {
    output.append(parseInlineMarkdown(line, baseSize: baseSize, extra: extra))
    output.append(NSAttributedString(string: "\n", attributes: extra))
}

func markdownAttributedString(_ markdown: String) -> NSAttributedString {
    let output = NSMutableAttributedString(string: "")
    let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
    let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var inCodeBlock = false

    for rawLine in lines {
        let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
            inCodeBlock.toggle()
            continue
        }

        if inCodeBlock {
            appendMarkdownLine(
                rawLine,
                to: output,
                baseSize: 14,
                extra: attributes(
                    font: convertedFont(baseSize: 14, bold: false, italic: false, monospace: true),
                    extra: [
                        .paragraphStyle: paragraphStyle(indent: 16),
                        .backgroundColor: inlineCodeBackgroundColor(),
                    ]
                )
            )
            continue
        }

        if trimmed.isEmpty {
            output.append(NSAttributedString(string: "\n", attributes: [.paragraphStyle: paragraphStyle()]))
            continue
        }

        if rawLine.hasPrefix("#") {
            let level = rawLine.prefix { $0 == "#" }.count
            let start = rawLine.index(rawLine.startIndex, offsetBy: level)
            guard start < rawLine.endIndex, rawLine[start] == " " else {
                appendMarkdownLine(rawLine, to: output, baseSize: 15, extra: [.paragraphStyle: paragraphStyle()])
                continue
            }
            let text = String(rawLine[rawLine.index(after: start)...])
            let size = max(17, 24 - CGFloat(level * 2))
            appendMarkdownLine(
                text,
                to: output,
                baseSize: size,
                extra: attributes(font: convertedFont(baseSize: size, bold: true, italic: false), extra: [.paragraphStyle: paragraphStyle()])
            )
            continue
        }

        if trimmed.hasPrefix(">") {
            let quote = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
            appendMarkdownLine(
                String(quote),
                to: output,
                baseSize: 15,
                extra: [
                    .paragraphStyle: paragraphStyle(indent: 18),
                    .foregroundColor: blockQuoteColor(),
                    NSAttributedString.Key("blockQuote"): true,
                ]
            )
            continue
        }

        if let match = rawLine.range(of: #"^\s*([-*+])\s+(.+)$"#, options: .regularExpression) {
            let text = rawLine[match].replacingOccurrences(of: #"^\s*([-*+])\s+"#, with: "", options: .regularExpression)
            let list = NSTextList(markerFormat: .disc, options: 0)
            appendMarkdownLine(String(text), to: output, baseSize: 15, extra: [.paragraphStyle: paragraphStyle(indent: 18, textLists: [list])])
            continue
        }

        if let match = rawLine.range(of: #"^\s*([0-9]+[.)])\s+(.+)$"#, options: .regularExpression) {
            let text = rawLine[match].replacingOccurrences(of: #"^\s*([0-9]+[.)])\s+"#, with: "", options: .regularExpression)
            let list = NSTextList(markerFormat: .decimal, options: 0)
            appendMarkdownLine(String(text), to: output, baseSize: 15, extra: [.paragraphStyle: paragraphStyle(indent: 18, textLists: [list])])
            continue
        }

        appendMarkdownLine(rawLine, to: output, baseSize: 15, extra: [.paragraphStyle: paragraphStyle()])
    }

    if markdown.hasSuffix("\n") == false, output.string.hasSuffix("\n") {
        output.deleteCharacters(in: NSRange(location: output.length - 1, length: 1))
    }
    return output
}

struct MarkdownFontTraits {
    var pointSize: CGFloat = 15
    var bold = false
    var italic = false
    var monospace = false
}

func markdownFontTraits(_ attrs: [NSAttributedString.Key: Any]) -> MarkdownFontTraits {
    guard let font = attrs[.font] as? PlatformFont else {
        return MarkdownFontTraits()
    }

    #if targetEnvironment(macCatalyst)
    let symbolicTraits = font.fontDescriptor.symbolicTraits
    return MarkdownFontTraits(
        pointSize: font.pointSize,
        bold: symbolicTraits.contains(.traitBold),
        italic: symbolicTraits.contains(.traitItalic),
        monospace: symbolicTraits.contains(.traitMonoSpace)
    )
    #else
    let fontManagerTraits = NSFontManager.shared.traits(of: font)
    let symbolicTraits = font.fontDescriptor.symbolicTraits
    return MarkdownFontTraits(
        pointSize: font.pointSize,
        bold: fontManagerTraits.contains(.boldFontMask),
        italic: fontManagerTraits.contains(.italicFontMask),
        monospace: symbolicTraits.contains(.monoSpace)
    )
    #endif
}

func markdownLineAttributes(_ attributed: NSAttributedString, lineRange: NSRange) -> [NSAttributedString.Key: Any] {
    if lineRange.length > 0 {
        return attributed.attributes(at: lineRange.location, effectiveRange: nil)
    }
    if lineRange.location < attributed.length {
        return attributed.attributes(at: lineRange.location, effectiveRange: nil)
    }
    if attributed.length > 0 {
        return attributed.attributes(at: attributed.length - 1, effectiveRange: nil)
    }
    return [:]
}

func markdownParagraphStyle(_ attrs: [NSAttributedString.Key: Any]) -> NSParagraphStyle? {
    attrs[.paragraphStyle] as? NSParagraphStyle
}

func markdownListPrefix(_ attrs: [NSAttributedString.Key: Any]) -> String? {
    guard let list = markdownParagraphStyle(attrs)?.textLists.first else {
        return nil
    }
    return list.markerFormat == .decimal ? "1. " : "- "
}

func isMarkdownCodeBlockLine(_ attrs: [NSAttributedString.Key: Any]) -> Bool {
    let traits = markdownFontTraits(attrs)
    let paragraphStyle = markdownParagraphStyle(attrs)
    return traits.monospace
        && attrs[.backgroundColor] != nil
        && (paragraphStyle?.textLists.isEmpty ?? true)
        && (paragraphStyle?.headIndent ?? 0) >= 12
}

func isMarkdownBlockQuoteLine(_ attrs: [NSAttributedString.Key: Any]) -> Bool {
    if (attrs[NSAttributedString.Key("blockQuote")] as? Bool) == true {
        return true
    }
    guard let paragraphStyle = markdownParagraphStyle(attrs),
          paragraphStyle.textLists.isEmpty,
          attrs[.backgroundColor] == nil else {
        return false
    }
    return paragraphStyle.headIndent >= 18
}

func markdownHeadingPrefix(_ attributed: NSAttributedString, lineRange: NSRange) -> String? {
    guard lineRange.length > 0 else {
        return nil
    }

    var sawText = false
    var minimumSize = CGFloat.greatestFiniteMagnitude
    var allBold = true
    attributed.enumerateAttributes(in: lineRange, options: []) { attrs, range, _ in
        let text = (attributed.string as NSString).substring(with: range)
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return
        }
        let traits = markdownFontTraits(attrs)
        sawText = true
        minimumSize = min(minimumSize, traits.pointSize)
        allBold = allBold && traits.bold
    }

    guard sawText, allBold, minimumSize >= 16.5 else {
        return nil
    }

    if minimumSize >= 21.5 { return "# " }
    if minimumSize >= 19.5 { return "## " }
    if minimumSize >= 17.5 { return "### " }
    return "#### "
}

func markdownLinkTarget(_ value: Any?) -> String? {
    if let url = value as? URL {
        return url.absoluteString
    }
    if let url = value as? NSURL {
        return url.absoluteString
    }
    if let string = value as? String, !string.isEmpty {
        return string
    }
    return nil
}

func markdownEscapedCode(_ text: String) -> String {
    if text.contains("`") == false {
        return "`\(text)`"
    }
    return "`` \(text.replacingOccurrences(of: "``", with: "` `")) ``"
}

func markdownInlineString(
    _ attributed: NSAttributedString,
    lineRange: NSRange,
    suppressFontStyles: Bool = false
) -> String {
    guard lineRange.length > 0 else {
        return ""
    }

    let nsString = attributed.string as NSString
    var output = ""
    attributed.enumerateAttributes(in: lineRange, options: []) { attrs, range, _ in
        let text = nsString.substring(with: range)
        guard text.isEmpty == false else {
            return
        }

        let hasContent = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let traits = markdownFontTraits(attrs)
        var rendered = text

        if let link = markdownLinkTarget(attrs[.link]), hasContent {
            rendered = "[\(rendered)](\(link))"
        } else if traits.monospace, attrs[.backgroundColor] != nil, hasContent {
            rendered = markdownEscapedCode(rendered)
        } else if !suppressFontStyles && traits.bold && traits.italic && hasContent {
            rendered = "***\(rendered)***"
        } else if !suppressFontStyles && traits.bold && hasContent {
            rendered = "**\(rendered)**"
        } else if !suppressFontStyles && traits.italic && hasContent {
            rendered = "*\(rendered)*"
        }

        output += rendered
    }
    return output
}

func markdownLineString(_ attributed: NSAttributedString, lineRange: NSRange) -> String {
    let attrs = markdownLineAttributes(attributed, lineRange: lineRange)

    if let headingPrefix = markdownHeadingPrefix(attributed, lineRange: lineRange) {
        let inline = markdownInlineString(attributed, lineRange: lineRange, suppressFontStyles: true)
        return headingPrefix + inline
    }

    let inline = markdownInlineString(attributed, lineRange: lineRange)
    if let listPrefix = markdownListPrefix(attrs) {
        return listPrefix + inline
    }
    if isMarkdownBlockQuoteLine(attrs) {
        return "> " + inline
    }
    return inline
}

func markdownString(_ attributed: NSAttributedString) -> String {
    let text = attributed.string
    guard text.isEmpty == false else {
        return ""
    }

    let lines = text.components(separatedBy: "\n")
    var lineRanges: [NSRange] = []
    var location = 0
    for line in lines {
        let length = (line as NSString).length
        lineRanges.append(NSRange(location: location, length: length))
        location += length + 1
    }

    var outputLines: [String] = []
    var index = 0
    while index < lineRanges.count {
        let attrs = markdownLineAttributes(attributed, lineRange: lineRanges[index])
        if isMarkdownCodeBlockLine(attrs) {
            outputLines.append("```")
            while index < lineRanges.count {
                let codeAttrs = markdownLineAttributes(attributed, lineRange: lineRanges[index])
                guard isMarkdownCodeBlockLine(codeAttrs) else {
                    break
                }
                outputLines.append((text as NSString).substring(with: lineRanges[index]))
                index += 1
            }
            outputLines.append("```")
            continue
        }

        outputLines.append(markdownLineString(attributed, lineRange: lineRanges[index]))
        index += 1
    }

    return outputLines.joined(separator: "\n")
}

func fetchEntry(context: NSManagedObjectContext, uuidString: String) throws -> NSManagedObject {
    guard let uuid = UUID(uuidString: uuidString) else {
        throw ToolError.invalid("invalid UUID: \(uuidString)")
    }
    let request = NSFetchRequest<NSManagedObject>(entityName: "JournalEntryMO")
    request.fetchLimit = 1
    request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
    guard let entry = try context.fetch(request).first else {
        throw ToolError.notFound("entry not found: \(uuidString)")
    }
    return entry
}

func defaultJournal(context: NSManagedObjectContext) throws -> NSManagedObject? {
    let request = NSFetchRequest<NSManagedObject>(entityName: "JournalMO")
    request.sortDescriptors = [
        NSSortDescriptor(key: "sortOrder", ascending: false),
        NSSortDescriptor(key: "createdDate", ascending: true),
    ]
    request.fetchLimit = 1
    return try context.fetch(request).first
}

func applyText(entry: NSManagedObject, title: NSAttributedString, body: NSAttributedString, now: Date, creating: Bool) throws {
    entry.setValue(try rtfData(title), forKey: "title")
    entry.setValue(try rtfData(body), forKey: "text")
    entry.setValue(Int16(body.string.count), forKey: "textLength")
    let assetPlacementWrapper = creating ? nil : entry.value(forKey: "mergeableAttributes") as? NSObject
    let mergeableAttributes = creating
        ? try makeMergeableAttributes(title: title, text: body, preservingAssetPlacementFrom: assetPlacementWrapper)
        : try makeReplacingMergeableAttributes(title: title, text: body, from: assetPlacementWrapper)
    entry.setValue(mergeableAttributes, forKey: "mergeableAttributes")
    entry.setValue(now, forKey: "updatedDate")
    entry.setValue(now, forKey: "entryDataUpdateDate")
    entry.setValue(true, forKey: "showTitle")
    entry.setValue(false, forKey: "isUploadedToCloud")
    if creating {
        entry.setValue(now, forKey: "createdDate")
        entry.setValue(now, forKey: "entryDate")
        entry.setValue(now, forKey: "momentDateForSorting")
    }
}

func entryTitle(_ entry: NSManagedObject) -> String {
    rtfString(entry.value(forKey: "title") as? Data).trimmingCharacters(in: .newlines)
}

func entryText(_ entry: NSManagedObject) -> String {
    markdownString(rtfAttributedString(entry.value(forKey: "text") as? Data))
}

func describeAttributes(_ value: Any) -> String {
    if let url = value as? URL {
        return "URL:\(url.absoluteString)"
    }
    if let font = value as? PlatformFont {
        #if targetEnvironment(macCatalyst)
        return "UIFont:\(font.fontName):\(font.pointSize)"
        #else
        return "NSFont:\(font.fontName):\(font.pointSize)"
        #endif
    }
    if let color = value as? PlatformColor {
        #if targetEnvironment(macCatalyst)
        return "UIColor:\(color.description)"
        #else
        return "NSColor:\(color.description)"
        #endif
    }
    if let style = value as? NSParagraphStyle {
        return "NSParagraphStyle:head=\(style.headIndent):first=\(style.firstLineHeadIndent)"
    }
    return "\(type(of: value)):\(value)"
}

func printAttributedDebug(label: String, attributed: NSAttributedString) {
    print("\(label).string: \(String(reflecting: attributed.string))")
    if attributed.length == 0 {
        print("\(label).runs: <empty>")
        return
    }
    attributed.enumerateAttributes(in: NSRange(location: 0, length: attributed.length)) { attrs, range, _ in
        let rendered = attrs.map { key, value in
            "\(key.rawValue)=\(describeAttributes(value))"
        }.sorted()
        print("\(label).run \(range.location)..<\(range.location + range.length): \(rendered)")
    }
}

func decodedMergeableText(_ entry: NSManagedObject) -> NSAttributedString? {
    guard let wrapper = entry.value(forKey: "mergeableAttributes") as? NSObject else {
        return nil
    }
    var value = MergeableEntryAttributesOpaque()
    let crText = SwiftValueBuffer(metadata: jsShimCRTextMetadata())
    withUnsafeMutableBytes(of: &value) { raw in
        jsShimWrappedMergeableEntryAttributesValue(wrapper, raw.baseAddress!)
        jsShimMergeableEntryTextGetter(raw.baseAddress!, crText.pointer)
    }
    crText.markInitialized()
    defer { crText.destroy() }
    return jsShimCRToNSText(crText.pointer)
}

func entryUUID(_ entry: NSManagedObject) -> String {
    (entry.value(forKey: "id") as? UUID)?.uuidString ?? ""
}

func boolValue(_ object: NSManagedObject, key: String) -> Bool {
    (object.value(forKey: key) as? Bool) == true
}

func uploadPredicateMatches(_ entry: NSManagedObject) -> Bool {
    !boolValue(entry, key: "isUploadedToCloud")
        && !boolValue(entry, key: "isTip")
        && !boolValue(entry, key: "isDraft")
        && !boolValue(entry, key: "isRemovedFromCloud")
}

func recordSystemFieldsLength(_ entry: NSManagedObject) -> Int {
    (entry.value(forKey: "recordSystemFields") as? Data)?.count ?? 0
}

func printSyncStatus(_ entry: NSManagedObject) {
    let fields = [
        entryUUID(entry),
        uploadPredicateMatches(entry) ? "queued" : "not-queued",
        "uploaded=\(boolValue(entry, key: "isUploadedToCloud") ? 1 : 0)",
        "removed=\(boolValue(entry, key: "isRemovedFromCloud") ? 1 : 0)",
        "draft=\(boolValue(entry, key: "isDraft") ? 1 : 0)",
        "tip=\(boolValue(entry, key: "isTip") ? 1 : 0)",
        "recordSystemFields=\(recordSystemFieldsLength(entry))",
        entryTitle(entry),
    ]
    print(fields.joined(separator: "\t"))
}

func uuidString(_ value: Any?) -> String? {
    (value as? UUID)?.uuidString
}

func uuidValue(_ object: NSManagedObject, key: String) -> UUID? {
    object.value(forKey: key) as? UUID
}

func dataValue(_ object: NSManagedObject, key: String) -> Data? {
    object.value(forKey: key) as? Data
}

func stringValue(_ object: NSManagedObject, key: String) -> String? {
    object.value(forKey: key) as? String
}

func intValue(_ object: NSManagedObject, key: String) -> Int? {
    if let value = object.value(forKey: key) as? NSNumber {
        return value.intValue
    }
    return nil
}

func dateString(_ value: Any?) -> String? {
    (value as? Date)?.ISO8601Format()
}

func decodeAssetOrdering(_ data: Data?) -> [UUID: Int] {
    guard let data,
          let array = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
        return [:]
    }
    var result: [UUID: Int] = [:]
    var index = 0
    while index + 1 < array.count {
        if let rawID = array[index] as? String,
           let id = UUID(uuidString: rawID),
           let rawOrder = array[index + 1] as? NSNumber {
            result[id] = rawOrder.intValue
        }
        index += 2
    }
    return result
}

func strippedVersionedJSONData(_ data: Data?) -> Data? {
    guard var data, !data.isEmpty else { return nil }
    if data.first == 0x01 {
        data.removeFirst()
    }
    return data
}

func decodedVersionedJSON(_ data: Data?) -> Any? {
    guard let jsonData = strippedVersionedJSONData(data) else { return nil }
    return try? JSONSerialization.jsonObject(with: jsonData)
}

func encodedVersionedJSON(_ object: Any) throws -> Data {
    var data = Data([0x01])
    data.append(try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
    return data
}

func encodedMetadataJSON(_ object: Any) throws -> Data {
    try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
}

func numericDouble(_ value: Any?) -> Double? {
    if let number = value as? NSNumber {
        return number.doubleValue
    }
    if let string = value as? String {
        return Double(string)
    }
    return nil
}

func decodedBase64RTFText(_ value: String) -> String? {
    guard let data = Data(base64Encoded: value) else { return nil }
    if let attributed = try? NSAttributedString(
        data: data,
        options: [.documentType: NSAttributedString.DocumentType.rtf],
        documentAttributes: nil
    ) {
        let text = attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
    return nil
}

func decodedArchivedColor(_ value: String) -> [String: Any]? {
    guard let data = Data(base64Encoded: value),
          let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
          let archive = plist as? [String: Any],
          let objects = archive["$objects"] as? [Any] else {
        return nil
    }

    for object in objects {
        guard let dictionary = object as? [String: Any] else { continue }
        var red = numericDouble(dictionary["UIRed-Double"]) ?? numericDouble(dictionary["UIRed"])
        var green = numericDouble(dictionary["UIGreen-Double"]) ?? numericDouble(dictionary["UIGreen"])
        var blue = numericDouble(dictionary["UIBlue-Double"]) ?? numericDouble(dictionary["UIBlue"])
        let alpha = numericDouble(dictionary["UIAlpha"]) ?? 1.0

        if (red == nil || green == nil || blue == nil),
           let rgbData = dictionary["NSRGB"] as? Data,
           let rgbString = String(data: rgbData, encoding: .utf8) {
            let parts = rgbString.split(separator: " ").compactMap { Double($0) }
            if parts.count >= 3 {
                red = parts[0]
                green = parts[1]
                blue = parts[2]
            }
        }

        guard let red, let green, let blue else { continue }
        let r = max(0, min(255, Int(round(red * 255))))
        let g = max(0, min(255, Int(round(green * 255))))
        let b = max(0, min(255, Int(round(blue * 255))))
        return [
            "red": red,
            "green": green,
            "blue": blue,
            "alpha": alpha,
            "hex": String(format: "#%02X%02X%02X", r, g, b),
        ]
    }
    return nil
}

func decodedMetadataDetails(_ metadata: Any?) -> [String: Any]? {
    guard let dictionary = metadata as? [String: Any] else { return nil }
    var decoded: [String: Any] = [:]

    if let prompt = dictionary["prompt"] as? String,
       let promptText = decodedBase64RTFText(prompt) {
        decoded["promptText"] = promptText
    }

    for key in ["colorLight", "colorDark"] {
        if let encoded = dictionary[key] as? String,
           let color = decodedArchivedColor(encoded) {
            decoded[key] = color
        }
    }

    for key in ["backgroundColorsLight", "backgroundColorsDark"] {
        if let encodedColors = dictionary[key] as? [String] {
            let colors = encodedColors.compactMap(decodedArchivedColor)
            if !colors.isEmpty {
                decoded[key] = colors
            }
        }
    }

    return decoded.isEmpty ? nil : decoded
}

func jsonString(_ value: Any, pretty: Bool = false) -> String {
    guard JSONSerialization.isValidJSONObject(value),
          let data = try? JSONSerialization.data(
            withJSONObject: value,
            options: pretty ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
          ),
          let string = String(data: data, encoding: .utf8) else {
        return "\(value)"
    }
    return string
}

func compactValue(_ value: Any, limit: Int = 80) -> String {
    let rendered: String
    if let string = value as? String {
        rendered = string
    } else if let number = value as? NSNumber {
        rendered = number.stringValue
    } else if value is NSNull {
        rendered = "null"
    } else {
        rendered = jsonString(value)
    }
    if rendered.count <= limit {
        return rendered
    }
    let end = rendered.index(rendered.startIndex, offsetBy: limit)
    return "\(rendered[..<end])..."
}

func metadataSummary(_ metadata: Any?) -> String {
    guard let dictionary = metadata as? [String: Any] else {
        if let metadata {
            return compactValue(metadata)
        }
        return "-"
    }

    let decoded = decodedMetadataDetails(metadata)
    let preferredKeys = [
        "assetIdentifier", "date", "placeName", "city", "latitude", "longitude",
        "duration", "recordingDate", "song", "artistName", "albumName",
        "title", "author", "mediaId", "mediaURL", "startTime", "endTime",
        "type", "distance", "calories", "valenceClassification",
        "reflectiveInterval", "labels", "domains", "isSlim", "revision",
        "indexableContent",
    ]
    var parts: [String] = []
    if let promptText = decoded?["promptText"] as? String {
        parts.append("promptText=\(compactValue(promptText, limit: 96))")
    }
    for key in ["colorLight", "colorDark"] {
        if let color = decoded?[key] as? [String: Any],
           let hex = color["hex"] as? String {
            parts.append("\(key)=\(hex)")
        }
    }
    for key in preferredKeys {
        guard let value = dictionary[key] else { continue }
        parts.append("\(key)=\(compactValue(value, limit: 48))")
    }
    if let visits = dictionary["visitsData"] as? [Any] {
        parts.append("visits=\(visits.count)")
        if let first = visits.first as? [String: Any] {
            for key in ["placeName", "city", "latitude", "longitude"] {
                if let value = first[key] {
                    parts.append("first.\(key)=\(compactValue(value, limit: 40))")
                }
            }
        }
    }
    if let transcriptSegments = dictionary["transcriptSegments"] as? [Any] {
        parts.append("transcriptSegments=\(transcriptSegments.count)")
    }
    if parts.isEmpty {
        parts = dictionary.keys.sorted().prefix(8).map { key in
            "\(key)=\(compactValue(dictionary[key] ?? "", limit: 48))"
        }
    }
    return parts.isEmpty ? "-" : parts.joined(separator: "; ")
}

func childObjects(_ object: NSManagedObject, key: String) -> [NSManagedObject] {
    if let set = object.value(forKey: key) as? NSSet {
        return set.allObjects.compactMap { $0 as? NSManagedObject }
    }
    if let set = object.value(forKey: key) as? Set<NSManagedObject> {
        return Array(set)
    }
    return []
}

func sanitizedPathComponent(_ string: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
    let scalars = string.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
    let result = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    return result.isEmpty ? "item" : result
}

func resolvedAttachmentURL(rootPath: String, relativePath: String) -> URL? {
    guard !relativePath.hasPrefix("/") else { return nil }
    let parts = relativePath.split(separator: "/", omittingEmptySubsequences: false)
    guard parts.allSatisfy({ $0 != "." && $0 != ".." && !$0.isEmpty }) else { return nil }
    return URL(fileURLWithPath: rootPath, isDirectory: true)
        .appendingPathComponent(relativePath, isDirectory: false)
}

func fileSize(_ url: URL) -> Int64? {
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
          let size = attrs[.size] as? NSNumber else {
        return nil
    }
    return size.int64Value
}

func fileAttachmentDictionary(_ attachment: NSManagedObject, rootPath: String) -> [String: Any] {
    var result: [String: Any] = [
        "id": uuidString(attachment.value(forKey: "id")) ?? "",
        "parentID": uuidString(attachment.value(forKey: "parentID")) ?? "",
        "index": intValue(attachment, key: "index") ?? 0,
        "name": stringValue(attachment, key: "name") ?? "",
        "relativePath": stringValue(attachment, key: "filePath") ?? "",
        "isUploadedToCloud": boolValue(attachment, key: "isUploadedToCloud"),
        "isRemovedFromCloud": boolValue(attachment, key: "isRemovedFromCloud"),
        "needsProcessing": boolValue(attachment, key: "needsProcessing"),
        "recordSystemFieldsBytes": dataValue(attachment, key: "recordSystemFields")?.count ?? 0,
    ]
    if let relativePath = stringValue(attachment, key: "filePath"),
       let url = resolvedAttachmentURL(rootPath: rootPath, relativePath: relativePath) {
        result["absolutePath"] = url.path
        result["exists"] = FileManager.default.fileExists(atPath: url.path)
        if let size = fileSize(url) {
            result["byteLength"] = size
        }
    }
    return result
}

func dataAttachmentDictionary(_ attachment: NSManagedObject) -> [String: Any] {
    [
        "index": intValue(attachment, key: "index") ?? 0,
        "byteLength": dataValue(attachment, key: "data")?.count ?? 0,
    ]
}

func sortedAttachmentAssets(entry: NSManagedObject, ordering: [UUID: Int]? = nil) -> [NSManagedObject] {
    let resolvedOrdering = ordering ?? decodeAssetOrdering(entry.value(forKey: "assetOrdering") as? Data)
    return childObjects(entry, key: "assets").sorted { left, right in
        let leftID = uuidValue(left, key: "id")
        let rightID = uuidValue(right, key: "id")
        let leftOrder = leftID.flatMap { resolvedOrdering[$0] } ?? Int.max
        let rightOrder = rightID.flatMap { resolvedOrdering[$0] } ?? Int.max
        if leftOrder != rightOrder { return leftOrder < rightOrder }
        let leftDate = left.value(forKey: "createdDate") as? Date ?? Date.distantPast
        let rightDate = right.value(forKey: "createdDate") as? Date ?? Date.distantPast
        if leftDate != rightDate { return leftDate < rightDate }
        return (leftID?.uuidString ?? "") < (rightID?.uuidString ?? "")
    }
}

func attachmentDictionaries(entry: NSManagedObject, rootPath: String) -> [[String: Any]] {
    let ordering = decodeAssetOrdering(entry.value(forKey: "assetOrdering") as? Data)
    return sortedAttachmentAssets(entry: entry, ordering: ordering).map { asset in
        let assetID = uuidValue(asset, key: "id")
        let fileAttachments = childObjects(asset, key: "fileAttachments")
            .sorted { (intValue($0, key: "index") ?? 0) < (intValue($1, key: "index") ?? 0) }
            .map { fileAttachmentDictionary($0, rootPath: rootPath) }
        let dataAttachments = childObjects(asset, key: "dataAttachments")
            .sorted { (intValue($0, key: "index") ?? 0) < (intValue($1, key: "index") ?? 0) }
            .map(dataAttachmentDictionary)
        let metadata = decodedVersionedJSON(dataValue(asset, key: "assetMetaData"))
        var result: [String: Any] = [
            "id": assetID?.uuidString ?? "",
            "assetType": stringValue(asset, key: "assetType") ?? "",
            "contentType": stringValue(asset, key: "contentType") ?? "",
            "source": stringValue(asset, key: "source") ?? "",
            "fileAttachment": stringValue(asset, key: "fileAttachment") ?? "",
            "createdDate": dateString(asset.value(forKey: "createdDate")) ?? "",
            "suggestionDate": dateString(asset.value(forKey: "suggestionDate")) ?? "",
            "isHidden": boolValue(asset, key: "isHidden"),
            "isSlim": boolValue(asset, key: "isSlim"),
            "isFullyRemoved": boolValue(asset, key: "isFullyRemoved"),
            "isUndoablyDeleted": boolValue(asset, key: "isUndoablyDeleted"),
            "isUploadedToCloud": boolValue(asset, key: "isUploadedToCloud"),
            "isRemovedFromCloud": boolValue(asset, key: "isRemovedFromCloud"),
            "minimumSupportedAppVersion": intValue(asset, key: "minimumSupportedAppVersion") ?? 0,
            "recordSystemFieldsBytes": dataValue(asset, key: "recordSystemFields")?.count ?? 0,
            "metadataByteLength": dataValue(asset, key: "assetMetaData")?.count ?? 0,
            "metadataSummary": metadataSummary(metadata),
            "fileAttachments": fileAttachments,
            "dataAttachments": dataAttachments,
        ]
        if let assetID, let order = ordering[assetID] {
            result["legacyOrder"] = order
        } else {
            result["legacyOrder"] = NSNull()
        }
        if let metadata {
            result["metadata"] = metadata
        }
        if let metadataDecoded = decodedMetadataDetails(metadata) {
            result["metadataDecoded"] = metadataDecoded
        }
        if let parentID = uuidString(asset.value(forKey: "parentID")), !parentID.isEmpty {
            result["parentID"] = parentID
        }
        if let suggestionID = uuidString(asset.value(forKey: "suggestionId")), !suggestionID.isEmpty {
            result["suggestionID"] = suggestionID
        }
        return result
    }
}

func encodeAssetOrdering(_ assetIDs: [UUID]) throws -> Data {
    var array: [Any] = []
    for (index, id) in assetIDs.enumerated() {
        array.append(id.uuidString)
        array.append(index)
    }
    return try JSONSerialization.data(withJSONObject: array)
}

func currentOrderedAssetIDs(entry: NSManagedObject) -> [UUID] {
    sortedAttachmentAssets(entry: entry).compactMap { uuidValue($0, key: "id") }
}

func validateReorderIDs(entry: NSManagedObject, requestedIDs: [UUID]) throws {
    let assets = sortedAttachmentAssets(entry: entry)
    let currentIDs = assets.compactMap { uuidValue($0, key: "id") }
    let currentSet = Set(currentIDs)
    let requestedSet = Set(requestedIDs)

    guard requestedIDs.count == requestedSet.count else {
        throw ToolError.invalid("attachments reorder contains duplicate asset IDs")
    }
    guard currentIDs.count == currentSet.count else {
        throw ToolError.invalid("entry has duplicate or missing asset IDs; refusing reorder")
    }
    guard currentSet == requestedSet else {
        let missing = currentSet.subtracting(requestedSet).map(\.uuidString).sorted()
        let unknown = requestedSet.subtracting(currentSet).map(\.uuidString).sorted()
        var parts: [String] = []
        if !missing.isEmpty { parts.append("missing: \(missing.joined(separator: ","))") }
        if !unknown.isEmpty { parts.append("unknown: \(unknown.joined(separator: ","))") }
        throw ToolError.invalid("attachments reorder must include exactly the current asset IDs (\(parts.joined(separator: "; ")))")
    }
}

func attachmentAsset(entry: NSManagedObject, id: UUID) throws -> NSManagedObject {
    for asset in childObjects(entry, key: "assets") {
        if uuidValue(asset, key: "id") == id {
            return asset
        }
    }
    throw ToolError.notFound("attachment not found in entry: \(id.uuidString)")
}

func refreshMergeableAssetPlacementFromLegacy(entry: NSManagedObject) throws {
    guard let wrapper = entry.value(forKey: "mergeableAttributes") as? NSObject else {
        return
    }

    var value = MergeableEntryAttributesOpaque()
    let placement = SwiftValueBuffer(metadata: jsShimMergeableEntryAssetsPlacementMetadata())
    withUnsafeMutableBytes(of: &value) { raw in
        jsShimWrappedMergeableEntryAttributesValue(wrapper, raw.baseAddress!)
        jsShimMergeableEntryAssetsPlacementFromLegacy(entry, placement.pointer)
        placement.markInitialized()
        jsShimMergeAssetPlacement(placement.pointer, raw.baseAddress!)
    }
    placement.destroy()

    let wrapperMetadata = jsWrappedMergeableEntryAttributesMetadata(0)
    let updatedWrapper = withUnsafeMutableBytes(of: &value) { raw in
        jsShimWrapMergeableEntryAttributes(raw.baseAddress!, wrapperMetadata)
    }
    entry.setValue(updatedWrapper, forKey: "mergeableAttributes")
}

func reorderAttachments(entry: NSManagedObject, assetIDs: [UUID]) throws {
    try validateReorderIDs(entry: entry, requestedIDs: assetIDs)
    entry.setValue(try encodeAssetOrdering(assetIDs), forKey: "assetOrdering")
    try refreshMergeableAssetPlacementFromLegacy(entry: entry)
    let now = Date()
    entry.setValue(now, forKey: "updatedDate")
    entry.setValue(now, forKey: "entryDataUpdateDate")
    entry.setValue(false, forKey: "isUploadedToCloud")
}

func resizeAttachment(entry: NSManagedObject, assetID: UUID, placement: String) throws {
    guard placement == "grid" || placement == "slim" else {
        throw ToolError.usage("attachments resize placement must be grid or slim")
    }
    let asset = try attachmentAsset(entry: entry, id: assetID)
    asset.setValue(placement == "slim", forKey: "isSlim")
    asset.setValue(false, forKey: "isUploadedToCloud")
    try refreshMergeableAssetPlacementFromLegacy(entry: entry)
    let now = Date()
    entry.setValue(now, forKey: "updatedDate")
    entry.setValue(now, forKey: "entryDataUpdateDate")
    entry.setValue(false, forKey: "isUploadedToCloud")
}

func normalizedCropRectString(x: Double, y: Double, width: Double, height: Double) -> String {
    String(
        format: "{{%.8g, %.8g}, {%.8g, %.8g}}",
        locale: Locale(identifier: "en_US_POSIX"),
        x,
        y,
        width,
        height
    )
}

func centeredCropRect(imageSize: CGSize, targetAspectRatio: Double) -> String {
    let width = max(Double(imageSize.width), 1)
    let height = max(Double(imageSize.height), 1)
    let imageAspectRatio = width / height

    if imageAspectRatio > targetAspectRatio {
        let normalizedWidth = targetAspectRatio / imageAspectRatio
        return normalizedCropRectString(
            x: (1 - normalizedWidth) / 2,
            y: 0,
            width: normalizedWidth,
            height: 1
        )
    }

    let normalizedHeight = imageAspectRatio / targetAspectRatio
    return normalizedCropRectString(
        x: 0,
        y: (1 - normalizedHeight) / 2,
        width: 1,
        height: normalizedHeight
    )
}

func jpegDataAndSize(forImageAt path: String) throws -> (Data, CGSize) {
    let url = URL(fileURLWithPath: path)
    #if targetEnvironment(macCatalyst)
    guard let image = PlatformImage(contentsOfFile: path),
          let data = image.jpegData(compressionQuality: 0.92) else {
        throw ToolError.invalid("failed to load image: \(path)")
    }
    return (data, image.size)
    #else
    guard let image = PlatformImage(contentsOf: url),
          let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
        throw ToolError.invalid("failed to load image: \(path)")
    }
    return (data, image.size)
    #endif
}

struct WrittenImageAttachment {
    let fileID: UUID
    let relativePath: String
    let imageSize: CGSize
}

struct WrittenFileAttachment {
    let fileID: UUID
    let relativePath: String
    let name: String
}

func writeJPEGImageAttachment(imagePath: String, entryID: String, assetID: UUID, rootPath: String) throws -> WrittenImageAttachment {
    let (imageData, imageSize) = try jpegDataAndSize(forImageAt: imagePath)
    let fileID = UUID()
    let relativePath = "\(entryID)/\(assetID.uuidString)/\(fileID.uuidString)_resized.jpeg"
    guard let destinationURL = resolvedAttachmentURL(rootPath: rootPath, relativePath: relativePath) else {
        throw ToolError.invalid("failed to build attachment destination path")
    }
    try FileManager.default.createDirectory(
        at: destinationURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try imageData.write(to: destinationURL, options: [.atomic])
    return WrittenImageAttachment(fileID: fileID, relativePath: relativePath, imageSize: imageSize)
}

func writeCopiedFileAttachment(sourcePath: String, entryID: String, assetID: UUID, rootPath: String, suffix: String, name: String) throws -> WrittenFileAttachment {
    let sourceURL = URL(fileURLWithPath: sourcePath)
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
        throw ToolError.invalid("attachment file does not exist: \(sourcePath)")
    }
    let fileID = UUID()
    let relativePath = "\(entryID)/\(assetID.uuidString)/\(fileID.uuidString)\(suffix)"
    guard let destinationURL = resolvedAttachmentURL(rootPath: rootPath, relativePath: relativePath) else {
        throw ToolError.invalid("failed to build attachment destination path")
    }
    try FileManager.default.createDirectory(
        at: destinationURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    return WrittenFileAttachment(fileID: fileID, relativePath: relativePath, name: name)
}

func isMOVFile(_ path: String) -> Bool {
    URL(fileURLWithPath: path).pathExtension.lowercased() == "mov"
}

func videoPresentationSize(forVideoAt path: String) throws -> CGSize {
    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    guard let track = asset.tracks(withMediaType: .video).first else {
        throw ToolError.invalid("failed to find a video track in: \(path)")
    }
    let transformed = track.naturalSize.applying(track.preferredTransform)
    let width = abs(transformed.width)
    let height = abs(transformed.height)
    guard width > 0, height > 0 else {
        throw ToolError.invalid("failed to read video dimensions from: \(path)")
    }
    return CGSize(width: width, height: height)
}

func insertFileAttachment(asset: NSManagedObject, assetID: UUID, fileID: UUID, relativePath: String, name: String) throws {
    guard let context = asset.managedObjectContext else {
        throw ToolError.invalid("asset is missing a managed object context")
    }
    let file = NSEntityDescription.insertNewObject(forEntityName: "JournalEntryAssetFileAttachmentMO", into: context)
    file.setValue(fileID, forKey: "id")
    file.setValue(assetID, forKey: "parentID")
    file.setValue(Int16(0), forKey: "index")
    file.setValue(false, forKey: "isRemovedFromCloud")
    file.setValue(false, forKey: "isUploadedToCloud")
    file.setValue(false, forKey: "needsProcessing")
    file.setValue(relativePath, forKey: "filePath")
    file.setValue(name, forKey: "name")
    file.setValue(asset, forKey: "asset")
    asset.mutableSetValue(forKey: "fileAttachments").add(file)
}

func insertImageFileAttachment(asset: NSManagedObject, assetID: UUID, written: WrittenImageAttachment) throws {
    try insertFileAttachment(
        asset: asset,
        assetID: assetID,
        fileID: written.fileID,
        relativePath: written.relativePath,
        name: "image"
    )
}

func insertCopiedFileAttachment(asset: NSManagedObject, assetID: UUID, written: WrittenFileAttachment) throws {
    try insertFileAttachment(
        asset: asset,
        assetID: assetID,
        fileID: written.fileID,
        relativePath: written.relativePath,
        name: written.name
    )
}

func photoMetadata(assetID: UUID, imageSize: CGSize, date: Date) throws -> Data {
    let metadata: [String: Any] = [
        "assetIdentifier": "journal_text:\(assetID.uuidString)",
        "date": date.timeIntervalSinceReferenceDate,
        "landscapeCropRect": centeredCropRect(imageSize: imageSize, targetAspectRatio: 16.0 / 9.0),
        "portraitCropRect": centeredCropRect(imageSize: imageSize, targetAspectRatio: 3.0 / 4.0),
        "squareCropRect": centeredCropRect(imageSize: imageSize, targetAspectRatio: 1.0),
    ]
    return try encodedMetadataJSON(metadata)
}

func musicMetadata(song: String, artistName: String, mediaID: String, startTime: Date) throws -> Data {
    let metadata: [String: Any] = [
        "artistName": artistName,
        "mediaId": mediaID,
        "mediaType": ["song": [:]],
        "song": song,
        "startTime": startTime.timeIntervalSinceReferenceDate,
    ]
    return try encodedMetadataJSON(metadata)
}

func addPhotoAttachment(entry: NSManagedObject, imagePath: String, rootPath: String, placement: String) throws -> UUID {
    guard placement == "grid" || placement == "slim" else {
        throw ToolError.usage("attachments add-photo placement must be grid or slim")
    }
    let entryID = entryUUID(entry)
    guard !entryID.isEmpty else {
        throw ToolError.invalid("entry is missing an id")
    }

    let assetID = UUID()
    let now = Date()
    let written = try writeJPEGImageAttachment(imagePath: imagePath, entryID: entryID, assetID: assetID, rootPath: rootPath)

    let currentIDs = currentOrderedAssetIDs(entry: entry)
    let asset = NSEntityDescription.insertNewObject(forEntityName: "JournalEntryAssetMO", into: entry.managedObjectContext!)
    asset.setValue(assetID, forKey: "id")
    asset.setValue(entry.value(forKey: "id") as? UUID, forKey: "parentID")
    asset.setValue("photo", forKey: "assetType")
    asset.setValue("", forKey: "contentType")
    asset.setValue("", forKey: "fileAttachment")
    asset.setValue("imagePicker", forKey: "source")
    asset.setValue(false, forKey: "isBeingEdited")
    asset.setValue(false, forKey: "isFullyRemoved")
    asset.setValue(false, forKey: "isHidden")
    asset.setValue(false, forKey: "isRemovedFromCloud")
    asset.setValue(placement == "slim", forKey: "isSlim")
    asset.setValue(false, forKey: "isUndoablyDeleted")
    asset.setValue(false, forKey: "isUploadedToCloud")
    asset.setValue(Int16(0), forKey: "minimumSupportedAppVersion")
    asset.setValue(false, forKey: "refreshAssetMetadata")
    asset.setValue(now, forKey: "createdDate")
    asset.setValue(try photoMetadata(assetID: assetID, imageSize: written.imageSize, date: now), forKey: "assetMetaData")
    asset.setValue(entry, forKey: "entry")
    entry.mutableSetValue(forKey: "assets").add(asset)
    try insertImageFileAttachment(asset: asset, assetID: assetID, written: written)

    entry.setValue(try encodeAssetOrdering(currentIDs + [assetID]), forKey: "assetOrdering")
    try refreshMergeableAssetPlacementFromLegacy(entry: entry)
    entry.setValue(now, forKey: "updatedDate")
    entry.setValue(now, forKey: "entryDataUpdateDate")
    entry.setValue(false, forKey: "isUploadedToCloud")
    return assetID
}

func addVideoAttachment(entry: NSManagedObject, videoPath: String, rootPath: String, placement: String) throws -> UUID {
    guard placement == "grid" || placement == "slim" else {
        throw ToolError.usage("attachments add-video placement must be grid or slim")
    }
    guard isMOVFile(videoPath) else {
        throw ToolError.usage("attachments add-video currently requires a .mov file")
    }
    let videoSize = try videoPresentationSize(forVideoAt: videoPath)
    let entryID = entryUUID(entry)
    guard !entryID.isEmpty else {
        throw ToolError.invalid("entry is missing an id")
    }

    let assetID = UUID()
    let suggestionID = UUID()
    let now = Date()
    let writtenVideo = try writeCopiedFileAttachment(
        sourcePath: videoPath,
        entryID: entryID,
        assetID: assetID,
        rootPath: rootPath,
        suffix: "_resized.mov",
        name: "video"
    )
    let currentIDs = currentOrderedAssetIDs(entry: entry)
    let asset = NSEntityDescription.insertNewObject(forEntityName: "JournalEntryAssetMO", into: entry.managedObjectContext!)
    asset.setValue(assetID, forKey: "id")
    asset.setValue(entry.value(forKey: "id") as? UUID, forKey: "parentID")
    asset.setValue("video", forKey: "assetType")
    asset.setValue("", forKey: "contentType")
    asset.setValue("", forKey: "fileAttachment")
    asset.setValue("suggestionSheet", forKey: "source")
    asset.setValue(false, forKey: "isBeingEdited")
    asset.setValue(false, forKey: "isFullyRemoved")
    asset.setValue(false, forKey: "isHidden")
    asset.setValue(false, forKey: "isRemovedFromCloud")
    asset.setValue(placement == "slim", forKey: "isSlim")
    asset.setValue(false, forKey: "isUndoablyDeleted")
    asset.setValue(false, forKey: "isUploadedToCloud")
    asset.setValue(Int16(0), forKey: "minimumSupportedAppVersion")
    asset.setValue(false, forKey: "refreshAssetMetadata")
    asset.setValue(now, forKey: "createdDate")
    asset.setValue(now, forKey: "suggestionDate")
    asset.setValue(suggestionID, forKey: "suggestionId")
    asset.setValue(try photoMetadata(assetID: assetID, imageSize: videoSize, date: now), forKey: "assetMetaData")
    asset.setValue(entry, forKey: "entry")
    entry.mutableSetValue(forKey: "assets").add(asset)
    try insertCopiedFileAttachment(asset: asset, assetID: assetID, written: writtenVideo)

    entry.setValue(try encodeAssetOrdering(currentIDs + [assetID]), forKey: "assetOrdering")
    try refreshMergeableAssetPlacementFromLegacy(entry: entry)
    entry.setValue(now, forKey: "updatedDate")
    entry.setValue(now, forKey: "entryDataUpdateDate")
    entry.setValue(false, forKey: "isUploadedToCloud")
    return assetID
}

func addLivePhotoAttachment(
    entry: NSManagedObject,
    imagePath: String,
    videoPath: String,
    rootPath: String,
    placement: String
) throws -> UUID {
    guard placement == "grid" || placement == "slim" else {
        throw ToolError.usage("attachments add-live-photo placement must be grid or slim")
    }
    guard isMOVFile(videoPath) else {
        throw ToolError.usage("attachments add-live-photo currently requires a .mov video component")
    }
    let entryID = entryUUID(entry)
    guard !entryID.isEmpty else {
        throw ToolError.invalid("entry is missing an id")
    }

    let assetID = UUID()
    let now = Date()
    let writtenImage = try writeJPEGImageAttachment(imagePath: imagePath, entryID: entryID, assetID: assetID, rootPath: rootPath)
    let writtenVideo = try writeCopiedFileAttachment(
        sourcePath: videoPath,
        entryID: entryID,
        assetID: assetID,
        rootPath: rootPath,
        suffix: "_resized.mov",
        name: "video"
    )
    let currentIDs = currentOrderedAssetIDs(entry: entry)

    let asset = NSEntityDescription.insertNewObject(forEntityName: "JournalEntryAssetMO", into: entry.managedObjectContext!)
    asset.setValue(assetID, forKey: "id")
    asset.setValue(entry.value(forKey: "id") as? UUID, forKey: "parentID")
    asset.setValue("livePhoto", forKey: "assetType")
    asset.setValue("", forKey: "contentType")
    asset.setValue("", forKey: "fileAttachment")
    asset.setValue("imagePicker", forKey: "source")
    asset.setValue(false, forKey: "isBeingEdited")
    asset.setValue(false, forKey: "isFullyRemoved")
    asset.setValue(false, forKey: "isHidden")
    asset.setValue(false, forKey: "isRemovedFromCloud")
    asset.setValue(placement == "slim", forKey: "isSlim")
    asset.setValue(false, forKey: "isUndoablyDeleted")
    asset.setValue(false, forKey: "isUploadedToCloud")
    asset.setValue(Int16(0), forKey: "minimumSupportedAppVersion")
    asset.setValue(false, forKey: "refreshAssetMetadata")
    asset.setValue(now, forKey: "createdDate")
    asset.setValue(try photoMetadata(assetID: assetID, imageSize: writtenImage.imageSize, date: now), forKey: "assetMetaData")
    asset.setValue(entry, forKey: "entry")
    entry.mutableSetValue(forKey: "assets").add(asset)
    try insertImageFileAttachment(asset: asset, assetID: assetID, written: writtenImage)
    try insertCopiedFileAttachment(asset: asset, assetID: assetID, written: writtenVideo)

    entry.setValue(try encodeAssetOrdering(currentIDs + [assetID]), forKey: "assetOrdering")
    try refreshMergeableAssetPlacementFromLegacy(entry: entry)
    entry.setValue(now, forKey: "updatedDate")
    entry.setValue(now, forKey: "entryDataUpdateDate")
    entry.setValue(false, forKey: "isUploadedToCloud")
    return assetID
}

func addMusicAttachment(
    entry: NSManagedObject,
    song: String,
    artistName: String,
    mediaID: String,
    coverPath: String,
    rootPath: String,
    placement: String
) throws -> UUID {
    guard placement == "grid" || placement == "slim" else {
        throw ToolError.usage("attachments add-music placement must be grid or slim")
    }
    guard !song.isEmpty else { throw ToolError.usage("attachments add-music requires a non-empty --song") }
    guard !artistName.isEmpty else { throw ToolError.usage("attachments add-music requires a non-empty --artist") }
    guard !mediaID.isEmpty else { throw ToolError.usage("attachments add-music requires a non-empty --media-id") }

    let entryID = entryUUID(entry)
    guard !entryID.isEmpty else {
        throw ToolError.invalid("entry is missing an id")
    }

    let assetID = UUID()
    let suggestionID = UUID()
    let now = Date()
    let written = try writeJPEGImageAttachment(imagePath: coverPath, entryID: entryID, assetID: assetID, rootPath: rootPath)
    let currentIDs = currentOrderedAssetIDs(entry: entry)

    let asset = NSEntityDescription.insertNewObject(forEntityName: "JournalEntryAssetMO", into: entry.managedObjectContext!)
    asset.setValue(assetID, forKey: "id")
    asset.setValue(entry.value(forKey: "id") as? UUID, forKey: "parentID")
    asset.setValue("music", forKey: "assetType")
    asset.setValue("", forKey: "contentType")
    asset.setValue("", forKey: "fileAttachment")
    asset.setValue("suggestionSheet", forKey: "source")
    asset.setValue(false, forKey: "isBeingEdited")
    asset.setValue(false, forKey: "isFullyRemoved")
    asset.setValue(false, forKey: "isHidden")
    asset.setValue(false, forKey: "isRemovedFromCloud")
    asset.setValue(placement == "slim", forKey: "isSlim")
    asset.setValue(false, forKey: "isUndoablyDeleted")
    asset.setValue(false, forKey: "isUploadedToCloud")
    asset.setValue(Int16(0), forKey: "minimumSupportedAppVersion")
    asset.setValue(false, forKey: "refreshAssetMetadata")
    asset.setValue(now, forKey: "createdDate")
    asset.setValue(now, forKey: "suggestionDate")
    asset.setValue(suggestionID, forKey: "suggestionId")
    asset.setValue(try musicMetadata(song: song, artistName: artistName, mediaID: mediaID, startTime: now), forKey: "assetMetaData")
    asset.setValue(entry, forKey: "entry")
    entry.mutableSetValue(forKey: "assets").add(asset)
    try insertImageFileAttachment(asset: asset, assetID: assetID, written: written)

    entry.setValue(try encodeAssetOrdering(currentIDs + [assetID]), forKey: "assetOrdering")
    try refreshMergeableAssetPlacementFromLegacy(entry: entry)
    entry.setValue(now, forKey: "updatedDate")
    entry.setValue(now, forKey: "entryDataUpdateDate")
    entry.setValue(false, forKey: "isUploadedToCloud")
    return assetID
}

func removePathIfPresent(_ url: URL) {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
        return
    }
    do {
        try FileManager.default.removeItem(at: url)
    } catch {
        fputs("failed to remove attachment file path: \(url.path): \(error)\n", stderr)
    }
}

func removeAttachmentFiles(entryID: String, assetID: UUID, rootPath: String) {
    let rootURL = URL(fileURLWithPath: rootPath, isDirectory: true)
    let assetURL = rootURL
        .appendingPathComponent(entryID, isDirectory: true)
        .appendingPathComponent(assetID.uuidString, isDirectory: true)
    removePathIfPresent(assetURL)

    let cacheURL = URL(fileURLWithPath: "\(NSHomeDirectory())/Library/Group Containers/group.com.apple.moments/Library/Caches", isDirectory: true)
    guard let cacheItems = try? FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil) else {
        return
    }
    let prefix = "thumb-\(assetID.uuidString)-"
    for item in cacheItems where item.lastPathComponent.hasPrefix(prefix) {
        removePathIfPresent(item)
    }
}

struct AttachmentFileCleanup {
    let entryID: String
    let assetID: UUID
    let rootPath: String
}

func deleteAttachment(entry: NSManagedObject, assetID: UUID, rootPath: String, keepFiles: Bool) throws -> AttachmentFileCleanup? {
    let asset = try attachmentAsset(entry: entry, id: assetID)
    let remainingIDs = sortedAttachmentAssets(entry: entry)
        .compactMap { uuidValue($0, key: "id") }
        .filter { $0 != assetID }
    let id = entryUUID(entry)

    entry.mutableSetValue(forKey: "assets").remove(asset)
    asset.managedObjectContext?.delete(asset)
    entry.setValue(try encodeAssetOrdering(remainingIDs), forKey: "assetOrdering")
    try refreshMergeableAssetPlacementFromLegacy(entry: entry)
    let now = Date()
    entry.setValue(now, forKey: "updatedDate")
    entry.setValue(false, forKey: "isUploadedToCloud")

    return keepFiles ? nil : AttachmentFileCleanup(entryID: id, assetID: assetID, rootPath: rootPath)
}

func normalizeAttachmentMetadata(entry: NSManagedObject, assetIDs: [UUID]) throws -> Int {
    let assets: [NSManagedObject]
    if assetIDs.isEmpty {
        assets = childObjects(entry, key: "assets")
    } else {
        assets = try assetIDs.map { try attachmentAsset(entry: entry, id: $0) }
    }

    var changed = 0
    for asset in assets {
        guard var metadata = dataValue(asset, key: "assetMetaData"),
              metadata.count >= 2,
              metadata.first == 0x01 else {
            continue
        }
        let second = metadata[metadata.index(after: metadata.startIndex)]
        guard second == 0x7B || second == 0x5B else {
            continue
        }
        metadata.removeFirst()
        asset.setValue(metadata, forKey: "assetMetaData")
        asset.setValue(false, forKey: "isUploadedToCloud")
        changed += 1
    }

    if changed > 0 {
        let now = Date()
        entry.setValue(now, forKey: "updatedDate")
        entry.setValue(now, forKey: "entryDataUpdateDate")
        entry.setValue(false, forKey: "isUploadedToCloud")
    }
    return changed
}

func printAttachmentTypes(context: NSManagedObjectContext) throws {
    let request = NSFetchRequest<NSManagedObject>(entityName: "JournalEntryAssetMO")
    let assets = try context.fetch(request)
    var counts: [String: Int] = [:]
    for asset in assets {
        let type = stringValue(asset, key: "assetType") ?? "<nil>"
        let contentType = stringValue(asset, key: "contentType") ?? "<nil>"
        let source = stringValue(asset, key: "source") ?? "<nil>"
        counts["\(type)\t\(contentType)\t\(source)", default: 0] += 1
    }
    print("assetType\tcontentType\tsource\tcount")
    for key in counts.keys.sorted() {
        print("\(key)\t\(counts[key] ?? 0)")
    }
}

func printAttachmentList(entry: NSManagedObject, rootPath: String, asJSON: Bool) {
    let attachments = attachmentDictionaries(entry: entry, rootPath: rootPath)
    if asJSON {
        let payload: [String: Any] = [
            "entryID": entryUUID(entry),
            "title": entryTitle(entry),
            "attachmentRoot": rootPath,
            "attachments": attachments,
        ]
        print(jsonString(payload, pretty: true))
        return
    }

    print("entry: \(entryUUID(entry))")
    print("title: \(entryTitle(entry))")
    print("attachmentRoot: \(rootPath)")
    print("count: \(attachments.count)")
    for (position, attachment) in attachments.enumerated() {
        let files = attachment["fileAttachments"] as? [[String: Any]] ?? []
        let dataAttachments = attachment["dataAttachments"] as? [[String: Any]] ?? []
        print("")
        print("[\(position)] \(attachment["id"] ?? "")")
        print("  order: \(attachment["legacyOrder"] ?? "-")")
        print("  type: \(attachment["assetType"] ?? "")")
        print("  contentType: \(attachment["contentType"] ?? "")")
        print("  source: \(attachment["source"] ?? "")")
        print("  flags: hidden=\((attachment["isHidden"] as? Bool) == true ? 1 : 0) slim=\((attachment["isSlim"] as? Bool) == true ? 1 : 0) removed=\((attachment["isFullyRemoved"] as? Bool) == true ? 1 : 0) uploaded=\((attachment["isUploadedToCloud"] as? Bool) == true ? 1 : 0)")
        print("  metadata: \(attachment["metadataSummary"] ?? "-")")
        if files.isEmpty {
            print("  files: -")
        } else {
            print("  files:")
            for file in files {
                let exists = (file["exists"] as? Bool) == true ? "exists" : "missing"
                let size = file["byteLength"].map { " bytes=\($0)" } ?? ""
                print("    [\(file["index"] ?? 0)] \(file["name"] ?? "") \(exists)\(size)")
                print("        \(file["relativePath"] ?? "")")
            }
        }
        if !dataAttachments.isEmpty {
            print("  data:")
            for data in dataAttachments {
                print("    [\(data["index"] ?? 0)] bytes=\(data["byteLength"] ?? 0)")
            }
        }
    }
}

func exportAttachments(entry: NSManagedObject, rootPath: String, outputPath: String) throws {
    let attachments = attachmentDictionaries(entry: entry, rootPath: rootPath)
    let outputURL = URL(fileURLWithPath: outputPath, isDirectory: true)
    try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
    let manifest: [String: Any] = [
        "entryID": entryUUID(entry),
        "title": entryTitle(entry),
        "attachmentRoot": rootPath,
        "attachments": attachments,
    ]
    let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
    try manifestData.write(to: outputURL.appendingPathComponent("manifest.json"))

    for (position, attachment) in attachments.enumerated() {
        let id = "\(attachment["id"] ?? "")"
        let type = sanitizedPathComponent("\(attachment["assetType"] ?? "asset")")
        let dirName = "\(String(format: "%03d", position))_\(type)_\(sanitizedPathComponent(id))"
        let assetURL = outputURL.appendingPathComponent(dirName, isDirectory: true)
        try FileManager.default.createDirectory(at: assetURL, withIntermediateDirectories: true, attributes: nil)

        var sidecar = attachment
        let metadata = sidecar.removeValue(forKey: "metadata")
        let metadataDecoded = sidecar.removeValue(forKey: "metadataDecoded")
        let sidecarData = try JSONSerialization.data(withJSONObject: sidecar, options: [.prettyPrinted, .sortedKeys])
        try sidecarData.write(to: assetURL.appendingPathComponent("asset.json"))
        if let metadata,
           JSONSerialization.isValidJSONObject(metadata),
           let metadataData = try? JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys]) {
            try metadataData.write(to: assetURL.appendingPathComponent("metadata.json"))
        }
        if let metadataDecoded,
           JSONSerialization.isValidJSONObject(metadataDecoded),
           let decodedData = try? JSONSerialization.data(withJSONObject: metadataDecoded, options: [.prettyPrinted, .sortedKeys]) {
            try decodedData.write(to: assetURL.appendingPathComponent("metadata-decoded.json"))
        }

        let files = attachment["fileAttachments"] as? [[String: Any]] ?? []
        for file in files {
            guard let relativePath = file["relativePath"] as? String,
                  let sourceURL = resolvedAttachmentURL(rootPath: rootPath, relativePath: relativePath) else {
                fputs("skip unsafe attachment path for \(id): \(file["relativePath"] ?? "")\n", stderr)
                continue
            }
            let index = file["index"] as? Int ?? 0
            let sourceName = sourceURL.lastPathComponent
            let destinationName = "\(String(format: "%02d", index))_\(sanitizedPathComponent(sourceName))"
            let destinationURL = assetURL.appendingPathComponent(destinationName)
            guard FileManager.default.fileExists(atPath: sourceURL.path) else {
                fputs("missing attachment file: \(sourceURL.path)\n", stderr)
                continue
            }
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            } catch {
                fputs("failed to copy attachment file: \(sourceURL.path): \(error)\n", stderr)
                continue
            }
        }
    }
    print(outputURL.path)
}

func readBody(path: String?) throws -> String {
    guard let path else { throw ToolError.usage("--body is required") }
    return try String(contentsOfFile: path, encoding: .utf8)
}

func save(_ context: NSManagedObjectContext) throws {
    if context.hasChanges {
        try context.save()
    }
}

func run() throws {
    var options = try parseOptions()
    if options.command == "debug-markdown" {
        let body = try readBody(path: options.bodyPath)
        let attributed = markdownAttributedString(body)
        let restored = rtfAttributedString(try rtfData(attributed))
        print(markdownString(restored), terminator: "")
        return
    }

    switch options.command {
    case "list", "get", "sync-status", "debug-attrs":
        options.readOnly = true
    case "attachments":
        let mutatingSubcommands: Set<String> = [
            "reorder", "resize", "delete", "normalize-metadata",
            "add-photo", "add-video", "add-live-photo", "add-music",
        ]
        options.readOnly = !mutatingSubcommands.contains(options.operands.first ?? "")
    default:
        options.readOnly = false
    }

    try bootstrapJournalShared()
    let context = try makeContext(storePath: options.storePath, readOnly: options.readOnly)

    switch options.command {
    case "list":
        let request = NSFetchRequest<NSManagedObject>(entityName: "JournalEntryMO")
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
        let entries = try context.fetch(request)
        for entry in entries {
            let deleted = (entry.value(forKey: "recentlyDeleted") as? Bool) == true ? "deleted" : "active"
            let created = entry.value(forKey: "createdDate") as? Date
            let updated = entry.value(forKey: "updatedDate") as? Date
            print([
                entryUUID(entry),
                deleted,
                created?.ISO8601Format() ?? "",
                updated?.ISO8601Format() ?? "",
                entryTitle(entry)
            ].joined(separator: "\t"))
        }

    case "get":
        guard options.operands.count == 1 else { throw ToolError.usage("get requires UUID") }
        let entry = try fetchEntry(context: context, uuidString: options.operands[0])
        print("id: \(entryUUID(entry))")
        print("title: \(entryTitle(entry))")
        if let created = entry.value(forKey: "createdDate") as? Date { print("created: \(created.ISO8601Format())") }
        if let updated = entry.value(forKey: "updatedDate") as? Date { print("updated: \(updated.ISO8601Format())") }
        print("---")
        let text = entryText(entry)
        print(text, terminator: text.hasSuffix("\n") ? "" : "\n")

    case "add":
        guard let title = options.title else { throw ToolError.usage("add requires --title") }
        let body = try readBody(path: options.bodyPath)
        let attributedTitle = plainAttributed(title)
        let attributedBody = markdownAttributedString(body)
        let now = Date()
        let entry = NSEntityDescription.insertNewObject(forEntityName: "JournalEntryMO", into: context)
        let uuid = UUID()
        entry.setValue(uuid, forKey: "id")
        entry.setValue("blankEntry", forKey: "entryType")
        entry.setValue(false, forKey: "isDraft")
        entry.setValue(false, forKey: "isFullyRemoved")
        entry.setValue(false, forKey: "isRemovedFromCloud")
        entry.setValue(false, forKey: "recentlyDeleted")
        entry.setValue(false, forKey: "showPhotoMemoryBanner")
        entry.setValue(false, forKey: "flagged")
        entry.setValue(false, forKey: "isUploadedToCloud")
        entry.setValue(Int16(0), forKey: "minimumSupportedAppVersion")
        entry.setValue(Int16(0), forKey: "minimumSupportedAppVersionMode")
        try applyText(entry: entry, title: attributedTitle, body: attributedBody, now: now, creating: true)
        if let journal = try defaultJournal(context: context) {
            entry.mutableSetValue(forKey: "journals").add(journal)
        }
        try save(context)
        print(uuid.uuidString)

    case "update":
        guard options.operands.count == 1 else { throw ToolError.usage("update requires UUID") }
        let entry = try fetchEntry(context: context, uuidString: options.operands[0])
        let title = options.title.map(plainAttributed)
            ?? rtfAttributedString(entry.value(forKey: "title") as? Data)
        let body = options.bodyPath == nil
            ? rtfAttributedString(entry.value(forKey: "text") as? Data)
            : markdownAttributedString(try readBody(path: options.bodyPath))
        try applyText(entry: entry, title: title, body: body, now: Date(), creating: false)
        try save(context)
        print(entryUUID(entry))

    case "delete":
        guard options.operands.count == 1 else { throw ToolError.usage("delete requires UUID") }
        let entry = try fetchEntry(context: context, uuidString: options.operands[0])
        if options.hardDelete {
            let id = entryUUID(entry)
            context.delete(entry)
            try save(context)
            print(id)
            return
        }
        let now = Date()
        entry.setValue(true, forKey: "recentlyDeleted")
        entry.setValue(false, forKey: "isUploadedToCloud")
        entry.setValue(now, forKey: "deletedOnDate")
        entry.setValue(now, forKey: "updatedDate")
        if entry.value(forKey: "recentlyDeletedEntryDate") == nil {
            entry.setValue(entry.value(forKey: "entryDate") as? Date ?? now, forKey: "recentlyDeletedEntryDate")
        }
        try save(context)
        print(entryUUID(entry))

    case "purge":
        guard options.operands.count == 1 else { throw ToolError.usage("purge requires UUID") }
        let entry = try fetchEntry(context: context, uuidString: options.operands[0])
        let id = entryUUID(entry)
        context.delete(entry)
        try save(context)
        print(id)

    case "sync-status":
        if options.operands.count == 1 {
            printSyncStatus(try fetchEntry(context: context, uuidString: options.operands[0]))
        } else if options.operands.isEmpty {
            let request = NSFetchRequest<NSManagedObject>(entityName: "JournalEntryMO")
            request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
            for entry in try context.fetch(request) {
                printSyncStatus(entry)
            }
        } else {
            throw ToolError.usage("sync-status accepts zero or one UUID")
        }

    case "queue-upload":
        guard options.operands.count == 1 else { throw ToolError.usage("queue-upload requires UUID") }
        let entry = try fetchEntry(context: context, uuidString: options.operands[0])
        entry.setValue(false, forKey: "isUploadedToCloud")
        entry.setValue(false, forKey: "isRemovedFromCloud")
        try save(context)
        printSyncStatus(entry)

    case "debug-attrs":
        guard options.operands.count == 1 else { throw ToolError.usage("debug-attrs requires UUID") }
        let entry = try fetchEntry(context: context, uuidString: options.operands[0])
        print("id: \(entryUUID(entry))")
        print("title: \(entryTitle(entry))")
        printAttributedDebug(label: "rtf.text", attributed: rtfAttributedString(entry.value(forKey: "text") as? Data))
        if let decoded = decodedMergeableText(entry) {
            printAttributedDebug(label: "crdt.text", attributed: decoded)
        } else {
            print("crdt.text: <missing mergeableAttributes>")
        }

    case "attachments":
        guard let subcommand = options.operands.first else {
            throw ToolError.usage("attachments requires a subcommand")
        }
        let rest = Array(options.operands.dropFirst())
        switch subcommand {
        case "types":
            guard rest.isEmpty else { throw ToolError.usage("attachments types accepts no operands") }
            try printAttachmentTypes(context: context)
        case "list":
            guard rest.count == 1 else { throw ToolError.usage("attachments list requires ENTRY_UUID") }
            let entry = try fetchEntry(context: context, uuidString: rest[0])
            printAttachmentList(entry: entry, rootPath: options.attachmentRootPath, asJSON: options.json)
        case "export":
            guard rest.count == 1 else { throw ToolError.usage("attachments export requires ENTRY_UUID") }
            guard let outputPath = options.outputPath else { throw ToolError.usage("attachments export requires --out DIR") }
            let entry = try fetchEntry(context: context, uuidString: rest[0])
            try exportAttachments(entry: entry, rootPath: options.attachmentRootPath, outputPath: outputPath)
        case "reorder":
            guard rest.count >= 2 else { throw ToolError.usage("attachments reorder requires ENTRY_UUID ASSET_UUID...") }
            let entry = try fetchEntry(context: context, uuidString: rest[0])
            let ids = try rest.dropFirst().map { raw -> UUID in
                guard let id = UUID(uuidString: raw) else {
                    throw ToolError.invalid("invalid asset UUID: \(raw)")
                }
                return id
            }
            try reorderAttachments(entry: entry, assetIDs: ids)
            try save(context)
            printAttachmentList(entry: entry, rootPath: options.attachmentRootPath, asJSON: options.json)
        case "resize":
            guard rest.count == 3 else { throw ToolError.usage("attachments resize requires ENTRY_UUID ASSET_UUID grid|slim") }
            let entry = try fetchEntry(context: context, uuidString: rest[0])
            guard let assetID = UUID(uuidString: rest[1]) else {
                throw ToolError.invalid("invalid asset UUID: \(rest[1])")
            }
            try resizeAttachment(entry: entry, assetID: assetID, placement: rest[2])
            try save(context)
            printAttachmentList(entry: entry, rootPath: options.attachmentRootPath, asJSON: options.json)
        case "delete":
            guard rest.count == 2 else { throw ToolError.usage("attachments delete requires ENTRY_UUID ASSET_UUID") }
            let entry = try fetchEntry(context: context, uuidString: rest[0])
            guard let assetID = UUID(uuidString: rest[1]) else {
                throw ToolError.invalid("invalid asset UUID: \(rest[1])")
            }
            let cleanup = try deleteAttachment(entry: entry, assetID: assetID, rootPath: options.attachmentRootPath, keepFiles: options.keepFiles)
            try save(context)
            if let cleanup {
                removeAttachmentFiles(entryID: cleanup.entryID, assetID: cleanup.assetID, rootPath: cleanup.rootPath)
            }
            printAttachmentList(entry: entry, rootPath: options.attachmentRootPath, asJSON: options.json)
        case "normalize-metadata":
            guard rest.count >= 1 else {
                throw ToolError.usage("attachments normalize-metadata requires ENTRY_UUID [ASSET_UUID...]")
            }
            let entry = try fetchEntry(context: context, uuidString: rest[0])
            let assetIDs = try rest.dropFirst().map { raw -> UUID in
                guard let id = UUID(uuidString: raw) else {
                    throw ToolError.invalid("invalid asset UUID: \(raw)")
                }
                return id
            }
            let changed = try normalizeAttachmentMetadata(entry: entry, assetIDs: assetIDs)
            try save(context)
            print("normalized: \(changed)")
        case "add-photo":
            guard rest.count == 2 || rest.count == 3 else {
                throw ToolError.usage("attachments add-photo requires ENTRY_UUID IMAGE_PATH [grid|slim]")
            }
            let entry = try fetchEntry(context: context, uuidString: rest[0])
            let placement = rest.count == 3 ? rest[2] : "grid"
            let assetID = try addPhotoAttachment(
                entry: entry,
                imagePath: rest[1],
                rootPath: options.attachmentRootPath,
                placement: placement
            )
            try save(context)
            print(assetID.uuidString)
        case "add-video":
            guard rest.count == 2 || rest.count == 3 else {
                throw ToolError.usage("attachments add-video requires ENTRY_UUID VIDEO.mov [grid|slim]")
            }
            let entry = try fetchEntry(context: context, uuidString: rest[0])
            let placement = rest.count == 3 ? rest[2] : "grid"
            let assetID = try addVideoAttachment(
                entry: entry,
                videoPath: rest[1],
                rootPath: options.attachmentRootPath,
                placement: placement
            )
            try save(context)
            print(assetID.uuidString)
        case "add-live-photo":
            guard rest.count == 3 || rest.count == 4 else {
                throw ToolError.usage("attachments add-live-photo requires ENTRY_UUID IMAGE_PATH VIDEO.mov [grid|slim]")
            }
            let entry = try fetchEntry(context: context, uuidString: rest[0])
            let placement = rest.count == 4 ? rest[3] : "grid"
            let assetID = try addLivePhotoAttachment(
                entry: entry,
                imagePath: rest[1],
                videoPath: rest[2],
                rootPath: options.attachmentRootPath,
                placement: placement
            )
            try save(context)
            print(assetID.uuidString)
        case "add-music":
            guard let entryUUID = rest.first else {
                throw ToolError.usage("attachments add-music requires ENTRY_UUID --song SONG --artist ARTIST --media-id ID --cover IMAGE_PATH [grid|slim]")
            }
            var index = 1
            var song: String?
            var artistName: String?
            var mediaID: String?
            var coverPath: String?
            var placement = "grid"
            while index < rest.count {
                let token = rest[index]
                switch token {
                case "--song":
                    guard index + 1 < rest.count else { throw ToolError.usage("--song requires a value") }
                    song = rest[index + 1]
                    index += 2
                case "--artist":
                    guard index + 1 < rest.count else { throw ToolError.usage("--artist requires a value") }
                    artistName = rest[index + 1]
                    index += 2
                case "--media-id":
                    guard index + 1 < rest.count else { throw ToolError.usage("--media-id requires a value") }
                    mediaID = rest[index + 1]
                    index += 2
                case "--cover":
                    guard index + 1 < rest.count else { throw ToolError.usage("--cover requires an image path") }
                    coverPath = rest[index + 1]
                    index += 2
                case "grid", "slim":
                    placement = token
                    index += 1
                default:
                    throw ToolError.usage("unknown attachments add-music option: \(token)")
                }
            }
            guard let song, let artistName, let mediaID, let coverPath else {
                throw ToolError.usage("attachments add-music requires ENTRY_UUID --song SONG --artist ARTIST --media-id ID --cover IMAGE_PATH [grid|slim]")
            }
            let entry = try fetchEntry(context: context, uuidString: entryUUID)
            let assetID = try addMusicAttachment(
                entry: entry,
                song: song,
                artistName: artistName,
                mediaID: mediaID,
                coverPath: coverPath,
                rootPath: options.attachmentRootPath,
                placement: placement
            )
            try save(context)
            print(assetID.uuidString)
        default:
            throw ToolError.usage("unknown attachments subcommand: \(subcommand)")
        }

    default:
        throw ToolError.usage(usage())
    }
}

do {
    try run()
} catch let error as ToolError {
    fputs("\(error.description)\n", stderr)
    exit(64)
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
