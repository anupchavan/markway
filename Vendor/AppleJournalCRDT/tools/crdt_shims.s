.text
.align 2

.globl _js_call_mergeable_entry_append_title
_js_call_mergeable_entry_append_title:
    stp x20, x30, [sp, #-16]!
    mov x20, x2
    bl _$s13JournalShared24MergeableEntryAttributesV6append5titleySS_tF
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_mergeable_entry_append_text
_js_call_mergeable_entry_append_text:
    stp x20, x30, [sp, #-16]!
    mov x20, x2
    bl _$s13JournalShared24MergeableEntryAttributesV6append4textySS_tF
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_wrap_mergeable_entry_attributes
_js_call_wrap_mergeable_entry_attributes:
    stp x20, x30, [sp, #-16]!
    mov x20, x1
    bl _$s13JournalShared31WrappedMergeableEntryAttributesCyAcA0deF0VcfC
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_cr_attributed_string_text_metadata
_js_call_cr_attributed_string_text_metadata:
    stp x20, x19, [sp, #-32]!
    stp x21, x30, [sp, #16]
    mov x0, #0
    bl _$s13JournalShared27MergeableTextAttributeScopeVMa
    mov x19, x0
    adrp x0, _$s13JournalShared27MergeableTextAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGE
    ldr x0, [x0, _$s13JournalShared27MergeableTextAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGEOFF]
    mov x1, x19
    bl _swift_getWitnessTable
    mov x20, x0
    mov x0, #0
    mov x1, x19
    mov x2, x20
    bl _$s9Coherence18CRAttributedStringVMa
    ldp x21, x30, [sp, #16]
    ldp x20, x19, [sp], #32
    ret

.globl _js_call_cr_attributed_string_title_metadata
_js_call_cr_attributed_string_title_metadata:
    stp x20, x19, [sp, #-32]!
    stp x21, x30, [sp, #16]
    mov x0, #0
    bl _$s13JournalShared28MergeableTitleAttributeScopeVMa
    mov x19, x0
    adrp x0, _$s13JournalShared28MergeableTitleAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGE
    ldr x0, [x0, _$s13JournalShared28MergeableTitleAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGEOFF]
    mov x1, x19
    bl _swift_getWitnessTable
    mov x20, x0
    mov x0, #0
    mov x1, x19
    mov x2, x20
    bl _$s9Coherence18CRAttributedStringVMa
    ldp x21, x30, [sp, #16]
    ldp x20, x19, [sp], #32
    ret

.globl _js_call_cr_attributed_string_text_attributes_metadata
_js_call_cr_attributed_string_text_attributes_metadata:
    stp x20, x19, [sp, #-32]!
    stp x21, x30, [sp, #16]
    mov x0, #0
    bl _$s13JournalShared27MergeableTextAttributeScopeVMa
    mov x19, x0
    adrp x0, _$s13JournalShared27MergeableTextAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGE
    ldr x0, [x0, _$s13JournalShared27MergeableTextAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGEOFF]
    mov x1, x19
    bl _swift_getWitnessTable
    mov x20, x0
    mov x0, #0
    mov x1, x19
    mov x2, x20
    bl _$s9Coherence18CRAttributedStringV10AttributesVMa
    ldp x21, x30, [sp, #16]
    ldp x20, x19, [sp], #32
    ret

.globl _js_call_cr_attributed_string_title_attributes_metadata
_js_call_cr_attributed_string_title_attributes_metadata:
    stp x20, x19, [sp, #-32]!
    stp x21, x30, [sp, #16]
    mov x0, #0
    bl _$s13JournalShared28MergeableTitleAttributeScopeVMa
    mov x19, x0
    adrp x0, _$s13JournalShared28MergeableTitleAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGE
    ldr x0, [x0, _$s13JournalShared28MergeableTitleAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGEOFF]
    mov x1, x19
    bl _swift_getWitnessTable
    mov x20, x0
    mov x0, #0
    mov x1, x19
    mov x2, x20
    bl _$s9Coherence18CRAttributedStringV10AttributesVMa
    ldp x21, x30, [sp, #16]
    ldp x20, x19, [sp], #32
    ret

.globl _js_call_destroy_swift_value
_js_call_destroy_swift_value:
    stp x30, x19, [sp, #-16]!
    ldr x16, [x1, #-8]
    ldr x16, [x16, #8]
    blr x16
    ldp x30, x19, [sp], #16
    ret

.globl _js_call_cr_attributed_string_from_ns_text
_js_call_cr_attributed_string_from_ns_text:
    stp x20, x19, [sp, #-32]!
    stp x22, x30, [sp, #16]
    mov x19, x0
    mov x20, x1
    bl _objc_retain
    mov x19, x0
    mov x0, #0
    bl _$s13JournalShared27MergeableTextAttributeScopeVMa
    mov x22, x0
    adrp x0, _$s13JournalShared27MergeableTextAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGE
    ldr x0, [x0, _$s13JournalShared27MergeableTextAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGEOFF]
    mov x1, x22
    bl _swift_getWitnessTable
    mov x2, x0
    mov x8, x20
    mov x0, x19
    mov x1, x22
    bl _$s9Coherence18CRAttributedStringVyACyxGSo012NSAttributedC0CcfC
    ldp x22, x30, [sp, #16]
    ldp x20, x19, [sp], #32
    ret

.globl _js_call_cr_attributed_string_from_ns_title
_js_call_cr_attributed_string_from_ns_title:
    stp x20, x19, [sp, #-32]!
    stp x22, x30, [sp, #16]
    mov x19, x0
    mov x20, x1
    bl _objc_retain
    mov x19, x0
    mov x0, #0
    bl _$s13JournalShared28MergeableTitleAttributeScopeVMa
    mov x22, x0
    adrp x0, _$s13JournalShared28MergeableTitleAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGE
    ldr x0, [x0, _$s13JournalShared28MergeableTitleAttributeScopeV9Coherence017CRAttributeStringeF0AAMc@GOTPAGEOFF]
    mov x1, x22
    bl _swift_getWitnessTable
    mov x2, x0
    mov x8, x20
    mov x0, x19
    mov x1, x22
    bl _$s9Coherence18CRAttributedStringVyACyxGSo012NSAttributedC0CcfC
    ldp x22, x30, [sp, #16]
    ldp x20, x19, [sp], #32
    ret

.globl _js_call_mergeable_entry_merge_text
_js_call_mergeable_entry_merge_text:
    stp x20, x30, [sp, #-16]!
    mov x20, x1
    bl _$s13JournalShared24MergeableEntryAttributesV5merge4texty9Coherence18CRAttributedStringVyAA0C18TextAttributeScopeVG_tF
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_mergeable_entry_merge_title
_js_call_mergeable_entry_merge_title:
    stp x20, x30, [sp, #-16]!
    mov x20, x1
    bl _$s13JournalShared24MergeableEntryAttributesV5merge5titley9Coherence18CRAttributedStringVyAA0C19TitleAttributeScopeVG_tF
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_cr_attributed_string_to_ns_text
_js_call_cr_attributed_string_to_ns_text:
    stp x20, x30, [sp, #-16]!
    mov x20, x0
    bl _$s9Coherence18CRAttributedStringV010attributedC0So012NSAttributedC0Cvg
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_cr_attributed_string_count
_js_call_cr_attributed_string_count:
    stp x20, x30, [sp, #-16]!
    mov x20, x0
    bl _$s9Coherence18CRAttributedStringV5countSivg
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_cr_attributed_string_remove_range
_js_call_cr_attributed_string_remove_range:
    stp x20, x30, [sp, #-16]!
    mov x20, x0
    mov x0, x1
    mov x1, x2
    bl _$s9Coherence18CRAttributedStringV14removeSubrangeyySnySiGF
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_cr_attributed_string_insert_ns
_js_call_cr_attributed_string_insert_ns:
    stp x20, x30, [sp, #-16]!
    mov x20, x0
    mov x0, x1
    mov x1, x2
    bl _$s9Coherence18CRAttributedStringV6insert10contentsOf2atySo012NSAttributedC0C_SitF
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_cr_attributed_string_add_attrs_text
_js_call_cr_attributed_string_add_attrs_text:
    stp x20, x30, [sp, #-16]!
    mov x20, x0
    mov x0, x1
    mov x1, x2
    mov x2, x3
    bl _$s9Coherence18CRAttributedStringV13addAttributes_5rangeyAC0E0Vyx_G_So8_NSRangeVtF
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_cr_attributed_string_add_attrs_title
_js_call_cr_attributed_string_add_attrs_title:
    stp x20, x30, [sp, #-16]!
    mov x20, x0
    mov x0, x1
    mov x1, x2
    mov x2, x3
    bl _$s9Coherence18CRAttributedStringV13addAttributes_5rangeyAC0E0Vyx_G_So8_NSRangeVtF
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_swift_fn0_return_pair
_js_call_swift_fn0_return_pair:
    stp x19, x30, [sp, #-16]!
    mov x9, x0
    mov x19, x1
    blr x9
    stp x0, x1, [x19]
    ldp x19, x30, [sp], #16
    ret

.globl _js_call_swift_provider_init
_js_call_swift_provider_init:
    stp x30, x19, [sp, #-16]!
    mov x9, x0
    mov x0, x1
    mov x1, x2
    blr x9
    ldp x30, x19, [sp], #16
    ret

.globl _js_call_swift_provider_init_to_buffer
_js_call_swift_provider_init_to_buffer:
    stp x30, x19, [sp, #-16]!
    mov x9, x0
    mov x0, x1
    mov x1, x2
    mov x8, x3
    blr x9
    ldp x30, x19, [sp], #16
    ret

.globl _js_call_journalui_cr_attributes
_js_call_journalui_cr_attributes:
    stp x30, x19, [sp, #-16]!
    mov x9, x0
    mov x8, x1
    mov x0, x2
    mov x1, x3
    mov x2, x4
    blr x9
    ldp x30, x19, [sp], #16
    ret

.globl _js_call_wrapped_mergeable_entry_attributes_value
_js_call_wrapped_mergeable_entry_attributes_value:
    stp x20, x30, [sp, #-16]!
    mov x20, x0
    mov x8, x1
    bl _$s13JournalShared31WrappedMergeableEntryAttributesC5valueAA0deF0Vvg
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_mergeable_entry_title_getter
_js_call_mergeable_entry_title_getter:
    stp x20, x30, [sp, #-16]!
    mov x20, x0
    mov x8, x1
    bl _$s13JournalShared24MergeableEntryAttributesV5title9Coherence18CRAttributedStringVyAA0C19TitleAttributeScopeVGvg
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_mergeable_entry_text_getter
_js_call_mergeable_entry_text_getter:
    stp x20, x30, [sp, #-16]!
    mov x20, x0
    mov x8, x1
    bl _$s13JournalShared24MergeableEntryAttributesV4text9Coherence18CRAttributedStringVyAA0C18TextAttributeScopeVGvg
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_mergeable_entry_asset_placement_getter
_js_call_mergeable_entry_asset_placement_getter:
    stp x20, x30, [sp, #-16]!
    mov x20, x0
    mov x8, x1
    bl _$s13JournalShared24MergeableEntryAttributesV14assetPlacementAA0cd6AssetsG0Vvg
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_mergeable_entry_assets_placement_metadata
_js_call_mergeable_entry_assets_placement_metadata:
    stp x30, x19, [sp, #-16]!
    mov x0, #0
    bl _$s13JournalShared29MergeableEntryAssetsPlacementVMa
    ldp x30, x19, [sp], #16
    ret

.globl _js_call_mergeable_entry_assets_placement_from_legacy
_js_call_mergeable_entry_assets_placement_from_legacy:
    stp x30, x19, [sp, #-16]!
    mov x8, x1
    bl _$s13JournalShared29MergeableEntryAssetsPlacementV26fromLegacyOrderingFieldsOfAcA0aD2MOC_tcfC
    ldp x30, x19, [sp], #16
    ret

.globl _js_call_mergeable_entry_assets_placement_debug_description
_js_call_mergeable_entry_assets_placement_debug_description:
    stp x20, x30, [sp, #-16]!
    mov x20, x0
    bl _$s13JournalShared29MergeableEntryAssetsPlacementV16debugDescriptionSSvg
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_mergeable_entry_assets_placement_add_asset
_js_call_mergeable_entry_assets_placement_add_asset:
    stp x20, x30, [sp, #-16]!
    sub sp, sp, #32
    mov x20, x0
    mov x0, x1
    cmp x2, #0
    b.ne 1f
    str x3, [sp]
    strb wzr, [sp, #8]
    b 2f
1:
    mov w8, #2
    str x8, [sp]
    mov w8, #1
    strb w8, [sp, #8]
2:
    str xzr, [sp, #16]
    strb wzr, [sp, #24]
    mov w8, #1
    strb w8, [sp, #25]
    mov x1, sp
    add x2, sp, #16
    bl _$s13JournalShared29MergeableEntryAssetsPlacementV14addOrMoveAsset6withID2to4fromy10Foundation4UUIDV_AA0jF0OALSgtF
    add sp, sp, #32
    ldp x20, x30, [sp], #16
    ret

.globl _js_call_mergeable_entry_merge_asset_placement
_js_call_mergeable_entry_merge_asset_placement:
    stp x20, x30, [sp, #-16]!
    mov x20, x1
    bl _$s13JournalShared24MergeableEntryAttributesV5merge14assetPlacementyAA0cd6AssetsH0V_tF
    ldp x20, x30, [sp], #16
    ret
