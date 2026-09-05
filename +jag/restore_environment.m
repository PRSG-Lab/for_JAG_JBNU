function restore_environment(state)
%RESTORE_ENVIRONMENT Restore caller folder, random generator and MATLAB path on success/error.
if isfolder(state.folder), cd(state.folder); end
rng(state.rng);
path(state.path);
end
