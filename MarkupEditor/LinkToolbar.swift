//
//  LinkToolbar.swift
//  MarkupEditor
//
//  Created by Steven Harris on 4/7/21.
//

import SwiftUI

public struct LinkToolbar: View {
    @Binding var showToolbar: Bool
    @Binding private var selectedWebView: MarkupWKWebView?
    @ObservedObject private var selectionState: SelectionState
    private var markupUIDelegate: MarkupUIDelegate?
    private var initialHref: String?
    // The href and link are the state for the toolbar
    @State private var href: String
    @State private var link: String
    // The previewed value holds on to what has been previewed, to
    // avoid doing the insert/modify unnecessarily
    @State private var previewedHref: String
    // The "arg" equivalent is to pass to insertLink
    private var argHRef: String? { href.isEmpty ? nil : href }
    
    public var body: some View {
        HStack(alignment: .bottom) {
            GeometryReader { geometry in
                HStack {
                    ToolbarTextField(
                        label: "Link URL",
                        placeholder: "Enter URL",
                        text: $href,
                        commitHandler: { save() },
                        validationHandler: { href.isValidURL }
                    )
                    .frame(width: geometry.size.width * 0.7)
                    ToolbarTextField(
                        label: "Text",
                        placeholder: "No text linked",
                        text: $link
                    )
                    .frame(width: geometry.size.width * 0.3)
                    .disabled(true)
                }
                .padding([.top], 2)
            }
            .padding([.trailing], 8)
            Divider()
            ToolbarTextButton(title: "Save", action: { self.save() }, width: 80)
                .disabled(!canBeSaved())
            ToolbarTextButton(title: "Cancel", action: { self.cancel() }, width: 80)
        }
        .onChange(of: selectionState.selection, perform: { value in
            href = selectionState.href ?? ""
            link = selectionState.link ?? selectionState.selection ?? ""
            previewedHref = href
        })
        .onChange(of: selectionState.href, perform: { value in
            href = selectionState.href ?? ""
            link = selectionState.link ?? selectionState.selection ?? ""
            previewedHref = href
        })
        .frame(height: 47)
        .padding([.leading, .trailing], 8)
        .padding([.top, .bottom], 2)
        Divider()
    }
    
    private func canBeSaved() -> Bool {
        return (!href.isEmpty && href.isValidURL) || (href.isEmpty && initialHref != nil)
    }
    
    public init(selectionState: SelectionState, selectedWebView: Binding<MarkupWKWebView?>, markupUIDelegate: MarkupUIDelegate? = nil, showToolbar: Binding<Bool>) {
        self.selectionState = selectionState
        _selectedWebView = selectedWebView
        self.markupUIDelegate = markupUIDelegate
        _showToolbar = showToolbar
        initialHref = selectionState.href
        _previewedHref = State(initialValue: selectionState.href ?? "")
        _href = State(initialValue: selectionState.href ?? "")
        _link = State(initialValue: selectionState.link ?? selectionState.selection ?? "")
    }
    
    private func previewed() -> Bool {
        // Return whether what we are seeing on the screen is the same as is in the toolbar
        return href == previewedHref
    }
    
    private func insertOrModify(handler: (()->Void)? = nil) {
        guard !previewed() else {
            handler?()
            return
        }
        if previewedHref.isEmpty && !href.isEmpty {
            selectedWebView?.insertLink(argHRef) {
                previewedHref = href
                handler?()
            }
        } else {
            selectedWebView?.insertLink(argHRef) {
                previewedHref = href
                handler?()
            }
        }
        
    }
    
    private func save() {
        // Save href it is hasn't been previewed, and then close
        guard canBeSaved() else { return }
        insertOrModify() {
            // TODO: The animation causes problems in UIKit. Need to figure it out
            withAnimation { showToolbar.toggle() }
        }
    }
    
    private func cancel() {
        // Restore href to its initial value, put things back the way they were, and then close
        href = initialHref ?? ""
        insertOrModify() {
            // TODO: The animation causes problems in UIKit. Need to figure it out
            withAnimation { showToolbar.toggle() }
        }
    }
    
}

struct LinkToolbar_Previews: PreviewProvider {
    static var previews: some View {
        LinkToolbar(selectionState: SelectionState(), selectedWebView: .constant(nil), showToolbar: .constant(true))
    }
}