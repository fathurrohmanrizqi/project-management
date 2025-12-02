<div class="space-y-6" x-data @comment-added.window="$wire.$refresh()">
    {{-- Add Comment Form --}}
    @php
        $ticket = $getRecord();
        $project = $ticket->project;
        $canComment = $project->members()->where('users.id', auth()->id())->exists();
    @endphp

    {{-- Comments List --}}
    @if($getState() && $getState()->count() > 0)
        <div class="space-y-4">
            @foreach($getState() as $comment)
                <div class="py-4 border-b border-gray-200 dark:border-gray-700 last:border-b-0">
                    <div class="flex items-start gap-x-4">
                        <div class="shrink-0">
                            <div
                                class="w-8 h-8 rounded-full bg-primary-500 flex items-center justify-center text-white font-medium text-sm">
                                {{ $comment->user ? substr($comment->user->name, 0, 1) : '?' }}
                            </div>
                        </div>
                        <div class="flex-1 min-w-0">
                            <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center mb-2">
                                <div class="text-sm font-medium text-gray-900 dark:text-gray-100">
                                    {{ $comment->user->name ?? 'Unknown User' }}
                                </div>
                                <div class="flex items-center gap-x-2">
                                    <div class="text-xs text-gray-500 dark:text-gray-400">
                                        {{ $comment->created_at->diffForHumans() }}
                                    </div>

                                    @if(auth()->user()->hasRole(['super_admin']) || $comment->user_id === auth()->id())
                                        <div class="flex gap-x-1">

                                            <!-- Edit Button -->
                                            <x-filament::icon-button
                                                icon="heroicon-o-pencil-square"
                                                color="gray"
                                                size="sm"
                                                :tooltip="$deleteAction->getLabel()"
                                                :action="$this->editCommentAction"
                                                :arguments="['commentId' => $comment->id]"
                                            />

                                            <!-- Delete Button -->
                                            <x-filament::icon-button
                                                icon="heroicon-o-trash"
                                                color="danger"
                                                size="sm"
                                                tooltip="Delete comment"
                                                :action="$this->deleteCommentAction"
                                                :arguments="['commentId' => $comment->id]"
                                            />

                                        </div>
                                    @endif


                                    {{-- @if(auth()->user()->hasRole(['super_admin']) || $comment->user_id === auth()->id())
                                        <div class="flex gap-x-1 items-center">
                                            {{ ($this->editCommentAction)(['commentId' => $comment->id]) }}

                                            {{ ($this->deleteCommentAction)(['commentId' => $comment->id]) }}
                                        </div>
                                    @endif --}}
                                </div>
                            </div>
                            <div class="prose prose-sm dark:prose-invert max-w-none">
                                {!! $comment->comment !!}
                            </div>
                            @if($comment->created_at != $comment->updated_at)
                                <div class=" text-xs text-gray-400 dark:text-gray-500 mt-1">
                                    (edited {{ $comment->updated_at->diffForHumans() }})
                                </div>
                            @endif
                        </div>
                    </div>
                </div>
            @endforeach
        </div>
    @else
        <div class="text-center py-8 text-gray-500 dark:text-gray-400">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto mb-3 text-gray-400" fill="none"
                viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            <p class="text-sm">No comments yet. Be the first to comment!</p>
        </div>
    @endif
    @if($canComment)
        @livewire('ticket-comment-form', ['ticket' => $ticket])
    @endif
</div>
