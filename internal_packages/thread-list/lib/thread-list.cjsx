_ = require 'underscore-plus'
React = require 'react'
{ListTabular, ModelList} = require 'ui-components'
{timestamp, subject} = require './formatting-utils'
{Actions,
 Utils,
 Thread,
 WorkspaceStore,
 NamespaceStore} = require 'inbox-exports'

ThreadListParticipants = require './thread-list-participants'
ThreadListStore = require './thread-list-store'

module.exports =
ThreadList = React.createClass
  displayName: 'ThreadList'

  componentWillMount: ->
    labelComponents = (thread) =>
      for label in @state.threadLabelComponents
        LabelComponent = label.view
        <LabelComponent thread={thread} />

    lastMessageType = (thread) ->
      myEmail = NamespaceStore.current()?.emailAddress
      msgs = thread.metadata
      return 'unknown' unless msgs and msgs instanceof Array and msgs.length > 0
      msg = msgs[msgs.length - 1]
      if thread.unread
        return 'unread'
      else if msg.from[0].email isnt myEmail
        return 'other'
      else if Utils.isForwardedMessage(msg)
        return 'forwarded'
      else
        return 'replied'

    c0 = new ListTabular.Column
      name: ""
      resolver: (thread) ->
        toggle = (event) ->
          ThreadListStore.view().selection.toggle(thread)
          event.stopPropagation()
        <div className="checkmark" onClick={toggle}><div className="inner"></div></div>

    c1 = new ListTabular.Column
      name: "★"
      resolver: (thread) ->
        <div className="thread-icon thread-icon-#{lastMessageType(thread)}"></div>

    c2 = new ListTabular.Column
      name: "Name"
      width: 200
      resolver: (thread) ->
        <ThreadListParticipants thread={thread} />

    c3 = new ListTabular.Column
      name: "Message"
      flex: 4
      resolver: (thread) ->
        attachments = []
        if thread.hasTagId('attachment')
          attachments = <div className="thread-icon thread-icon-attachment"></div>
        <span className="details">
          <span className="subject">{subject(thread.subject)}</span>
          <span className="snippet">{thread.snippet}</span>
          {attachments}
        </span>

    c4 = new ListTabular.Column
      name: "Date"
      resolver: (thread) ->
        <span className="timestamp">{timestamp(thread.lastMessageTimestamp)}</span>

    @columns = [c0, c1, c2, c3, c4]
    @commands =
      'core:remove-item': -> Actions.archiveCurrentThread()
      'core:remove-and-previous': -> Actions.archiveAndPrevious()
      'core:remove-and-next': -> Actions.archiveAndNext()
      'application:reply': @_onReply
      'application:reply-all': @_onReplyAll
      'application:forward': @_onForward
    @itemClassProvider = (item) ->
      React.addons.classSet
        'unread': item.isUnread()

  render: ->
    <ModelList
      dataStore={ThreadListStore}
      columns={@columns}
      commands={@commands}
      itemClassProvider={@itemClassProvider}
      className="thread-list"
      collection="thread" />

  # Additional Commands

  _onReply: ({focusedId}) ->
    return unless focusedId? and @_viewingFocusedThread()
    Actions.composeReply(threadId: focusedId)

  _onReplyAll: ({focusedId}) ->
    return unless focusedId? and @_viewingFocusedThread()
    Actions.composeReplyAll(threadId: focusedId)

  _onForward: ({focusedId}) ->
    return unless focusedId? and @_viewingFocusedThread()
    Actions.composeForward(threadId: focusedId)

  # Helpers

  _viewingFocusedThread: ->
    if WorkspaceStore.selectedLayoutMode() is "list"
      WorkspaceStore.sheet().type is "Thread"
    else
      true
